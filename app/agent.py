"""
Claude-powered natural-language cost Q&A agent.

Flow:
  1. User asks a question in plain English.
  2. Claude is given the finops.* view catalog and asked to call the
     `run_finops_sql` tool with a single read-only SQL query.
  3. We validate the query (SELECT/WITH only, finops schema only, single
     statement, row cap), execute it, and hand the result back to Claude.
  4. Claude turns the result into a plain-English answer for the stakeholder.

Guardrails live in `validate_sql` — anything that fails validation is never
executed against the warehouse.
"""

import os
import re
import json

import pandas as pd
from anthropic import Anthropic

from db import run_query
from queries import VIEW_CATALOG

MODEL = "claude-sonnet-5"
MAX_ROWS = 500
MAX_TOOL_ITERATIONS = 4

_FORBIDDEN_KEYWORDS = (
    "INSERT", "UPDATE", "DELETE", "MERGE", "DROP", "CREATE", "ALTER",
    "TRUNCATE", "GRANT", "REVOKE", "COPY", "USE ", "OPTIMIZE", "VACUUM",
    "EXEC", "CALL",
)

_ALLOWED_TABLE_PREFIX = "finops."


class SqlValidationError(Exception):
    pass


def _client() -> Anthropic:
    api_key = os.getenv("ANTHROPIC_API_KEY")
    if not api_key:
        raise RuntimeError(
            "ANTHROPIC_API_KEY is not set. Attach the anthropic-api-key secret "
            "resource to this Databricks App (see app.yaml)."
        )
    return Anthropic(api_key=api_key)


def _schema_prompt() -> str:
    lines = ["You can query the following views (all in the `finops` schema):\n"]
    for name, (description, columns) in VIEW_CATALOG.items():
        lines.append(f"- {name}: {description}\n  Columns: {columns}")
    return "\n".join(lines)


def validate_sql(raw_sql: str) -> str:
    """Raises SqlValidationError if the query is unsafe; otherwise returns a
    row-capped, single-statement version of the query safe to execute."""
    sql = raw_sql.strip().rstrip(";").strip()

    if not sql:
        raise SqlValidationError("Empty query.")

    if ";" in sql:
        raise SqlValidationError("Only a single SQL statement is allowed.")

    first_word = re.split(r"\s", sql, maxsplit=1)[0].upper()
    if first_word not in ("SELECT", "WITH"):
        raise SqlValidationError("Only SELECT queries are allowed.")

    upper_sql = sql.upper()
    for keyword in _FORBIDDEN_KEYWORDS:
        if re.search(rf"\b{keyword.strip()}\b", upper_sql):
            raise SqlValidationError(f"Query contains a forbidden keyword: {keyword.strip()}")

    tables_referenced = re.findall(r"\b(?:FROM|JOIN)\s+([a-zA-Z0-9_.`]+)", sql, flags=re.IGNORECASE)
    if not tables_referenced:
        raise SqlValidationError("Could not find a FROM/JOIN clause referencing a finops table.")
    for table in tables_referenced:
        cleaned = table.strip("`").lower()
        if not cleaned.startswith(_ALLOWED_TABLE_PREFIX):
            raise SqlValidationError(
                f"Query references '{table}', which is outside the finops schema. "
                "Only finops.* views may be queried."
            )

    if not re.search(r"\bLIMIT\s+\d+\b", upper_sql):
        sql = f"SELECT * FROM ({sql}) AS agent_subquery LIMIT {MAX_ROWS}"

    return sql


TOOLS = [
    {
        "name": "run_finops_sql",
        "description": (
            "Execute a single read-only SQL SELECT query against the finops "
            "reporting views and return the result rows. Only finops.* views "
            "may be referenced."
        ),
        "input_schema": {
            "type": "object",
            "properties": {
                "sql": {
                    "type": "string",
                    "description": "A single SELECT statement querying finops.* views only.",
                }
            },
            "required": ["sql"],
        },
    }
]

SYSTEM_PROMPT = f"""You are a FinOps cost analyst assistant for an Azure Databricks platform team.
Stakeholders ask you plain-English questions about Databricks cost, and you answer using real
data from the `finops` reporting schema.

Rules:
- To answer any question requiring data, call the `run_finops_sql` tool with one SELECT query.
- Only query views listed below, in the `finops` schema. Never guess at other tables.
- Prefer the pre-aggregated views (daily_cost, monthly_cost, top10_pipelines, etc.) over
  billing_master directly when they already answer the question.
- All monetary figures in these views are already in GBP unless a column name says otherwise.
- finops.pipeline_success_rate is a placeholder only — it cannot tell you about pipeline
  failures or reliability. Say so if asked and this is the only relevant view.
- After you get query results, answer conversationally with the actual numbers, in British
  English, formatted as GBP (£) unless the user asks for USD.
- If a question can't be answered from these views, say so plainly rather than guessing.

{_schema_prompt()}
"""


def ask(question: str, history: list[dict] | None = None) -> tuple[str, list[dict]]:
    """Answers a stakeholder question. Returns (answer_text, updated_history)."""
    client = _client()
    messages = list(history or [])
    messages.append({"role": "user", "content": question})

    for _ in range(MAX_TOOL_ITERATIONS):
        response = client.messages.create(
            model=MODEL,
            max_tokens=1024,
            system=SYSTEM_PROMPT,
            tools=TOOLS,
            messages=messages,
        )

        messages.append({"role": "assistant", "content": response.content})

        tool_uses = [block for block in response.content if block.type == "tool_use"]
        if not tool_uses:
            text = "".join(block.text for block in response.content if block.type == "text")
            return text, messages

        tool_results = []
        for tool_use in tool_uses:
            try:
                safe_sql = validate_sql(tool_use.input.get("sql", ""))
                df = run_query(safe_sql)
                result_payload = {
                    "row_count": len(df),
                    "rows": json.loads(df.head(200).to_json(orient="records")),
                }
                content = json.dumps(result_payload, default=str)
            except SqlValidationError as e:
                content = json.dumps({"error": f"Query rejected: {e}"})
            except Exception as e:
                content = json.dumps({"error": f"Query failed: {e}"})

            tool_results.append(
                {
                    "type": "tool_result",
                    "tool_use_id": tool_use.id,
                    "content": content,
                }
            )

        messages.append({"role": "user", "content": tool_results})

    return (
        "I wasn't able to reach a final answer within the allowed number of steps. "
        "Try rephrasing your question.",
        messages,
    )
