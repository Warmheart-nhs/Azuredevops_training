/******************************************************************************
Project     : Azure Databricks FinOps Accelerator
Script      : 21_job_daily_cost.sql
Purpose     : Job Daily Cost report — the job-level equivalent of
              14_pipeline_daily_cost.sql. The original 20-script set gave
              pipelines full daily/weekly/monthly/by-user detail but only a
              top-10 view for jobs; this closes that gap so data engineers
              get the same visibility into jobs.
Run Order   : 21st (after 20_top10_jobs.sql)
******************************************************************************/

USE finops;

CREATE OR REPLACE VIEW finops.job_daily_cost AS
SELECT
    usage_date,
    usage_metadata.job_id AS job_id,
    COUNT(*)                       AS runs,
    ROUND(SUM(total_cost_gbp), 2) AS daily_cost_gbp,
    ROUND(AVG(total_cost_gbp), 2) AS average_run_cost
FROM finops.billing_master
WHERE usage_metadata.job_id IS NOT NULL
GROUP BY usage_date, usage_metadata.job_id
ORDER BY usage_date DESC, daily_cost_gbp DESC;

SELECT * FROM finops.job_daily_cost ORDER BY usage_date DESC;
