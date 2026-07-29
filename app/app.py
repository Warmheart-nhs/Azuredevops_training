"""
Azure Databricks FinOps Accelerator — Stakeholder App

A Databricks App (Streamlit) that gives stakeholders:
  - Executive KPI cards and cost trend charts
  - Daily / weekly / monthly cost breakdowns
  - Budget vs actual tracking
  - Top 10 pipelines / jobs by spend
  - A Claude-powered natural-language Q&A agent over the same data
"""

import streamlit as st
import pandas as pd
import altair as alt

import queries as q
from db import run_query
import agent

st.set_page_config(page_title="Databricks FinOps", page_icon="\U0001F4B0", layout="wide")

st.title("Azure Databricks FinOps Dashboard")
st.caption("Cost visibility for Azure Databricks, sourced from system.billing tables via the finops schema.")

TAB_OVERVIEW, TAB_TRENDS, TAB_PIPELINES, TAB_BUDGET, TAB_AGENT = st.tabs(
    ["Executive Overview", "Cost Trends", "Pipelines & Jobs", "Budget vs Actual", "Ask the FinOps Agent"]
)


def _safe_query(sql: str) -> pd.DataFrame:
    try:
        return run_query(sql)
    except Exception as e:
        st.error(f"Query failed: {e}")
        return pd.DataFrame()


# ---------------------------------------------------------------------------
# Executive Overview
# ---------------------------------------------------------------------------
with TAB_OVERVIEW:
    kpis = _safe_query(q.EXECUTIVE_KPIS)
    if not kpis.empty:
        kpi_map = dict(zip(kpis["kpi"], kpis["kpi_value"]))
        cols = st.columns(4)
        card_order = [
            ("Today Spend (GBP)", "£{:,.2f}"),
            ("Weekly Spend (GBP)", "£{:,.2f}"),
            ("Monthly Spend (GBP)", "£{:,.2f}"),
            ("Total Spend (GBP)", "£{:,.2f}"),
        ]
        for col, (label, fmt) in zip(cols, card_order):
            value = kpi_map.get(label)
            col.metric(label, fmt.format(value) if value is not None else "n/a")

        cols2 = st.columns(4)
        entity_order = ["Total Workspaces", "Total Pipelines", "Total Jobs", "Total Users"]
        for col, label in zip(cols2, entity_order):
            value = kpi_map.get(label)
            col.metric(label, f"{int(value):,}" if value is not None else "n/a")

    st.divider()
    st.subheader("Daily Cost (last 90 days)")
    daily = _safe_query(q.DAILY_COST)
    if not daily.empty:
        chart = (
            alt.Chart(daily)
            .mark_bar()
            .encode(x="usage_date:T", y="daily_cost_gbp:Q", tooltip=list(daily.columns))
        )
        st.altair_chart(chart, use_container_width=True)
        st.dataframe(daily, use_container_width=True, hide_index=True)


# ---------------------------------------------------------------------------
# Cost Trends
# ---------------------------------------------------------------------------
with TAB_TRENDS:
    st.subheader("Cumulative Cost Trend")
    trend = _safe_query(q.COST_TREND)
    if not trend.empty:
        base = alt.Chart(trend).encode(x="usage_date:T")
        daily_line = base.mark_line(color="#4C78A8").encode(y="daily_cost:Q")
        running_line = base.mark_line(color="#F58518").encode(y="running_total:Q")
        st.altair_chart(daily_line + running_line, use_container_width=True)

    c1, c2 = st.columns(2)
    with c1:
        st.subheader("Weekly Cost")
        weekly = _safe_query(q.WEEKLY_COST)
        st.dataframe(weekly, use_container_width=True, hide_index=True)
    with c2:
        st.subheader("Monthly Cost")
        monthly = _safe_query(q.MONTHLY_COST)
        st.dataframe(monthly, use_container_width=True, hide_index=True)


# ---------------------------------------------------------------------------
# Pipelines & Jobs
# ---------------------------------------------------------------------------
with TAB_PIPELINES:
    c1, c2 = st.columns(2)
    with c1:
        st.subheader("Top 10 Most Expensive Pipelines")
        top_pipelines = _safe_query(q.TOP10_PIPELINES)
        st.dataframe(top_pipelines, use_container_width=True, hide_index=True)
        if not top_pipelines.empty:
            chart = (
                alt.Chart(top_pipelines)
                .mark_bar()
                .encode(x="total_cost_gbp:Q", y=alt.Y("pipeline_id:N", sort="-x"))
            )
            st.altair_chart(chart, use_container_width=True)
    with c2:
        st.subheader("Top 10 Most Expensive Jobs")
        top_jobs = _safe_query(q.TOP10_JOBS)
        st.dataframe(top_jobs, use_container_width=True, hide_index=True)
        if not top_jobs.empty:
            chart = (
                alt.Chart(top_jobs)
                .mark_bar()
                .encode(x="total_cost_gbp:Q", y=alt.Y("job_id:N", sort="-x"))
            )
            st.altair_chart(chart, use_container_width=True)

    st.divider()
    st.subheader("Pipeline Cost by User")
    st.dataframe(_safe_query(q.PIPELINE_BY_USER), use_container_width=True, hide_index=True)

    st.subheader("Estimated Pipeline Runtime")
    st.caption("Estimated from billing timestamps — not an official runtime metric.")
    st.dataframe(_safe_query(q.PIPELINE_RUNTIME), use_container_width=True, hide_index=True)


# ---------------------------------------------------------------------------
# Budget vs Actual
# ---------------------------------------------------------------------------
with TAB_BUDGET:
    st.subheader("Budget vs Actual (by month)")
    budget = _safe_query(q.BUDGET_VS_ACTUAL)
    if not budget.empty:
        st.dataframe(budget, use_container_width=True, hide_index=True)
        chart = (
            alt.Chart(budget.melt(id_vars="budget_month", value_vars=["budget_gbp", "actual_cost_gbp"]))
            .mark_bar(opacity=0.8)
            .encode(x="budget_month:N", y="value:Q", color="variable:N", xOffset="variable:N")
        )
        st.altair_chart(chart, use_container_width=True)
    else:
        st.info("No budget data yet — populate finops.monthly_budget (see sql/03_create_reference_tables.sql).")


# ---------------------------------------------------------------------------
# Ask the FinOps Agent
# ---------------------------------------------------------------------------
with TAB_AGENT:
    st.subheader("Ask the FinOps Agent")
    st.caption(
        "Ask questions in plain English, e.g. “What did we spend last week?” or "
        "“Which pipeline cost the most this month?” The agent only reads from the "
        "finops schema and cannot modify any data."
    )

    if "chat_display" not in st.session_state:
        st.session_state.chat_display = []
    if "chat_history" not in st.session_state:
        st.session_state.chat_history = []

    for role, content in st.session_state.chat_display:
        with st.chat_message(role):
            st.markdown(content)

    question = st.chat_input("Ask about Databricks cost...")
    if question:
        st.session_state.chat_display.append(("user", question))
        with st.chat_message("user"):
            st.markdown(question)

        with st.chat_message("assistant"):
            with st.spinner("Checking the finops data..."):
                try:
                    answer, updated_history = agent.ask(question, st.session_state.chat_history)
                    st.session_state.chat_history = updated_history
                except Exception as e:
                    answer = f"Sorry, something went wrong answering that: {e}"
            st.markdown(answer)
        st.session_state.chat_display.append(("assistant", answer))
