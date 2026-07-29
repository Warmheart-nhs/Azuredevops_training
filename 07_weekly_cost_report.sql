/******************************************************************************
Project     : Azure Databricks FinOps Accelerator
Script      : 07_weekly_cost_report.sql
Purpose     : Creates the Weekly Cost Reporting View.
Run Order   : 7th
******************************************************************************/

USE finops;

CREATE OR REPLACE VIEW finops.weekly_cost AS
SELECT
    YEAR(usage_date)        AS year,
    WEEKOFYEAR(usage_date)  AS week_number,
    MIN(usage_date)         AS week_start,
    MAX(usage_date)         AS week_end,
    ROUND(SUM(total_cost_gbp), 2) AS weekly_cost_gbp,
    ROUND(SUM(total_cost_usd), 2) AS weekly_cost_usd,
    COUNT(*)                                   AS billing_records,
    COUNT(DISTINCT workspace_id)               AS workspaces,
    COUNT(DISTINCT usage_metadata.dlt_pipeline_id) AS pipelines,
    COUNT(DISTINCT usage_metadata.job_id)      AS jobs,
    COUNT(DISTINCT identity_metadata.run_as)   AS users
FROM finops.billing_master
GROUP BY YEAR(usage_date), WEEKOFYEAR(usage_date)
ORDER BY year DESC, week_number DESC;

SELECT * FROM finops.weekly_cost;
