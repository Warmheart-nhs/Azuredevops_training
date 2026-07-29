/******************************************************************************
Project     : Azure Databricks FinOps Accelerator
Script      : 06_daily_cost_report.sql
Purpose     : Creates the Daily Cost Reporting View.
Run Order   : 6th
******************************************************************************/

USE finops;

CREATE OR REPLACE VIEW finops.daily_cost AS
SELECT
    usage_date,
    ROUND(SUM(total_cost_gbp), 2) AS daily_cost_gbp,
    ROUND(SUM(total_cost_usd), 2) AS daily_cost_usd,
    COUNT(*)                                   AS billing_records,
    COUNT(DISTINCT workspace_id)               AS workspaces,
    COUNT(DISTINCT usage_metadata.job_id)      AS jobs,
    COUNT(DISTINCT usage_metadata.dlt_pipeline_id) AS pipelines,
    COUNT(DISTINCT identity_metadata.run_as)   AS users
FROM finops.billing_master
GROUP BY usage_date
ORDER BY usage_date DESC;

SELECT * FROM finops.daily_cost ORDER BY usage_date DESC;
