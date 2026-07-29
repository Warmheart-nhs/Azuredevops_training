/******************************************************************************
Project     : Azure Databricks FinOps Accelerator
Script      : 14_pipeline_daily_cost.sql
Purpose     : Pipeline Daily Cost report.
Run Order   : 14th
******************************************************************************/

USE finops;

CREATE OR REPLACE VIEW finops.pipeline_daily_cost AS
SELECT
    usage_date,
    usage_metadata.dlt_pipeline_id AS pipeline_id,
    COUNT(*)                       AS runs,
    ROUND(SUM(total_cost_gbp), 2) AS daily_cost_gbp,
    ROUND(AVG(total_cost_gbp), 2) AS average_run_cost
FROM finops.billing_master
WHERE usage_metadata.dlt_pipeline_id IS NOT NULL
GROUP BY usage_date, usage_metadata.dlt_pipeline_id
ORDER BY usage_date DESC, daily_cost_gbp DESC;

SELECT * FROM finops.pipeline_daily_cost ORDER BY usage_date DESC;
