/******************************************************************************
Project     : Azure Databricks FinOps Accelerator
Script      : 13_top10_pipelines.sql
Purpose     : Top 10 Most Expensive Pipelines.
Run Order   : 13th
******************************************************************************/

USE finops;

CREATE OR REPLACE VIEW finops.top10_pipelines AS
SELECT
    usage_metadata.dlt_pipeline_id AS pipeline_id,
    COUNT(*)                       AS total_runs,
    ROUND(SUM(total_cost_gbp), 2) AS total_cost_gbp,
    ROUND(AVG(total_cost_gbp), 2) AS average_run_cost
FROM finops.billing_master
WHERE usage_metadata.dlt_pipeline_id IS NOT NULL
GROUP BY usage_metadata.dlt_pipeline_id
ORDER BY total_cost_gbp DESC
LIMIT 10;

SELECT * FROM finops.top10_pipelines;
