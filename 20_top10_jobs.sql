/******************************************************************************
Project     : Azure Databricks FinOps Accelerator
Script      : 20_top10_jobs.sql
Purpose     : Top 10 Most Expensive Jobs.
Run Order   : 20th (last)
******************************************************************************/

USE finops;

CREATE OR REPLACE VIEW finops.top10_jobs AS
SELECT
    usage_metadata.job_id AS job_id,
    COUNT(*)                       AS total_runs,
    ROUND(SUM(total_cost_gbp), 2) AS total_cost_gbp,
    ROUND(AVG(total_cost_gbp), 2) AS average_job_cost_gbp
FROM finops.billing_master
WHERE usage_metadata.job_id IS NOT NULL
GROUP BY usage_metadata.job_id
ORDER BY total_cost_gbp DESC
LIMIT 10;

SELECT * FROM finops.top10_jobs;
