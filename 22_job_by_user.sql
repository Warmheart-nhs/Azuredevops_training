/******************************************************************************
Project     : Azure Databricks FinOps Accelerator
Script      : 22_job_by_user.sql
Purpose     : Shows all jobs executed by each user, with execution count and
              total cost — the job-level equivalent of 17_pipeline_by_user.sql.
Run Order   : 22nd
******************************************************************************/

USE finops;

CREATE OR REPLACE VIEW finops.job_by_user AS
SELECT
    identity_metadata.run_as AS user_name,
    usage_metadata.job_id    AS job_id,
    COUNT(*)                       AS executions,
    ROUND(SUM(total_cost_gbp), 2) AS total_cost_gbp,
    ROUND(AVG(total_cost_gbp), 2) AS average_execution_cost
FROM finops.billing_master
WHERE identity_metadata.run_as IS NOT NULL
  AND usage_metadata.job_id IS NOT NULL
GROUP BY identity_metadata.run_as, usage_metadata.job_id
ORDER BY total_cost_gbp DESC;

SELECT * FROM finops.job_by_user;
