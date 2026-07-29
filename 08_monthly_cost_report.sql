/******************************************************************************
Project     : Azure Databricks FinOps Accelerator
Script      : 08_monthly_cost_report.sql
Purpose     : Creates the Monthly Cost Reporting View.
Business    : Management requires visibility into monthly Azure Databricks
              spend in USD and GBP to support budgeting and forecasting.
Run Order   : 8th
******************************************************************************/

USE finops;

CREATE OR REPLACE VIEW finops.monthly_cost AS
SELECT
    YEAR(usage_date)                        AS usage_year,
    MONTH(usage_date)                       AS usage_month,
    DATE_FORMAT(usage_date, 'MMMM yyyy')    AS reporting_month,
    MIN(usage_date)                         AS month_start,
    MAX(usage_date)                         AS month_end,
    ROUND(SUM(total_cost_usd), 2) AS monthly_cost_usd,
    ROUND(SUM(total_cost_gbp), 2) AS monthly_cost_gbp,
    ROUND(AVG(total_cost_gbp), 2) AS average_daily_cost_gbp,
    COUNT(*)                                   AS billing_records,
    COUNT(DISTINCT workspace_id)               AS workspaces,
    COUNT(DISTINCT usage_metadata.dlt_pipeline_id) AS pipelines,
    COUNT(DISTINCT usage_metadata.job_id)      AS jobs,
    COUNT(DISTINCT identity_metadata.run_as)   AS users
FROM finops.billing_master
GROUP BY YEAR(usage_date), MONTH(usage_date), DATE_FORMAT(usage_date, 'MMMM yyyy')
ORDER BY usage_year DESC, usage_month DESC;

SELECT * FROM finops.monthly_cost ORDER BY usage_year DESC, usage_month DESC;
