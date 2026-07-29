"""
Catalog of finops.* reporting views: the SQL the dashboard pages run, and
the schema context handed to the NL Q&A agent so it knows what it can query.

Keeping this in one place means the dashboard and the agent can never
disagree about what a view contains.
"""

# name -> (description, column list) — used to build the agent's system prompt
VIEW_CATALOG = {
    "finops.billing_master": (
        "Row-level billing detail. Every other view is derived from this one.",
        "account_id, workspace_id, usage_date, usage_start_time, usage_end_time, "
        "sku_name, cloud, usage_quantity, usage_unit, usage_metadata "
        "(struct incl. job_id, pipeline_id), identity_metadata (struct incl. run_as), "
        "custom_tags, unit_price_usd, total_cost_usd, total_cost_gbp",
    ),
    "finops.daily_cost": (
        "Total cost per calendar day.",
        "usage_date, daily_cost_gbp, daily_cost_usd, billing_records, workspaces, jobs, pipelines, users",
    ),
    "finops.weekly_cost": (
        "Total cost per ISO week.",
        "year, week_number, week_start, week_end, weekly_cost_gbp, weekly_cost_usd, "
        "billing_records, workspaces, pipelines, jobs, users",
    ),
    "finops.monthly_cost": (
        "Total cost per calendar month.",
        "usage_year, usage_month, reporting_month, month_start, month_end, "
        "monthly_cost_usd, monthly_cost_gbp, average_daily_cost_gbp, "
        "billing_records, workspaces, pipelines, jobs, users",
    ),
    "finops.executive_summary": (
        "Single-row headline KPIs: today/week/month/total spend and entity counts.",
        "total_spend_gbp, today_spend_gbp, weekly_spend_gbp, monthly_spend_gbp, "
        "total_workspaces, total_pipelines, total_jobs, total_users",
    ),
    "finops.executive_kpis": (
        "Same headline KPIs as executive_summary but as (kpi, kpi_value) rows — "
        "convenient for dashboard KPI cards.",
        "kpi, kpi_value",
    ),
    "finops.cost_trend": (
        "Daily cost plus a running cumulative total, for trend-line charts.",
        "usage_date, daily_cost, running_total",
    ),
    "finops.monthly_budget": (
        "Finance-approved budget per month. Reference table, not derived from billing.",
        "budget_month (yyyy-MM), budget_gbp, approved_by, created_timestamp",
    ),
    "finops.budget_vs_actual": (
        "Approved budget vs actual spend per month, with remaining budget and % used.",
        "budget_month, budget_gbp, actual_cost_gbp, remaining_budget_gbp, pct_of_budget_used",
    ),
    "finops.top10_pipelines": (
        "The 10 most expensive Lakeflow/DLT pipelines by total cost.",
        "pipeline_id, total_runs, total_cost_gbp, average_run_cost",
    ),
    "finops.pipeline_daily_cost": (
        "Cost per pipeline per day.",
        "usage_date, pipeline_id, runs, daily_cost_gbp, average_run_cost",
    ),
    "finops.pipeline_weekly_cost": (
        "Cost per pipeline per ISO week.",
        "usage_year, usage_week, week_start, week_end, pipeline_id, total_runs, "
        "weekly_cost_gbp, average_run_cost_gbp",
    ),
    "finops.pipeline_monthly_cost": (
        "Cost per pipeline per calendar month.",
        "usage_year, usage_month, reporting_month, pipeline_id, total_runs, "
        "monthly_cost_gbp, average_run_cost_gbp",
    ),
    "finops.pipeline_by_user": (
        "Which users ran which pipelines, execution counts and cost.",
        "user_name, pipeline_id, executions, total_cost_gbp, average_execution_cost",
    ),
    "finops.pipeline_runtime": (
        "Estimated pipeline runtime derived from billing timestamps (not an "
        "official runtime metric).",
        "pipeline_id, executions, average_runtime_minutes, maximum_runtime_minutes",
    ),
    "finops.pipeline_success_rate": (
        "Placeholder only — success/failure isn't in the billing data. "
        "Do not use this to answer questions about failures or reliability.",
        "pipeline_id, executions, status_source",
    ),
    "finops.top10_jobs": (
        "The 10 most expensive Databricks Jobs by total cost.",
        "job_id, total_runs, total_cost_gbp, average_job_cost_gbp",
    ),
}

EXECUTIVE_KPIS = "SELECT * FROM finops.executive_kpis"
EXECUTIVE_SUMMARY = "SELECT * FROM finops.executive_summary"
COST_TREND = "SELECT * FROM finops.cost_trend ORDER BY usage_date"
DAILY_COST = "SELECT * FROM finops.daily_cost ORDER BY usage_date DESC LIMIT 90"
WEEKLY_COST = "SELECT * FROM finops.weekly_cost ORDER BY year DESC, week_number DESC LIMIT 26"
MONTHLY_COST = "SELECT * FROM finops.monthly_cost ORDER BY usage_year DESC, usage_month DESC LIMIT 24"
BUDGET_VS_ACTUAL = "SELECT * FROM finops.budget_vs_actual ORDER BY budget_month DESC"
TOP10_PIPELINES = "SELECT * FROM finops.top10_pipelines"
TOP10_JOBS = "SELECT * FROM finops.top10_jobs"
PIPELINE_BY_USER = "SELECT * FROM finops.pipeline_by_user LIMIT 100"
PIPELINE_RUNTIME = "SELECT * FROM finops.pipeline_runtime LIMIT 50"
