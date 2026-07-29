/******************************************************************************
Project     : Azure Databricks FinOps Accelerator
Script      : 17_pipeline_by_user.sql
Purpose     : Shows all pipelines executed by each user, with execution
              count and total cost.
Run Order   : 17th
******************************************************************************/

USE finops;

CREATE OR REPLACE VIEW finops.pipeline_by_user AS
SELECT
    identity_metadata.run_as   AS user_name,
    usage_metadata.dlt_pipeline_id AS pipeline_id,
    COUNT(*)                       AS executions,
    ROUND(SUM(total_cost_gbp), 2) AS total_cost_gbp,
    ROUND(AVG(total_cost_gbp), 2) AS average_execution_cost
FROM finops.billing_master
WHERE identity_metadata.run_as IS NOT NULL
  AND usage_metadata.dlt_pipeline_id IS NOT NULL
GROUP BY identity_metadata.run_as, usage_metadata.dlt_pipeline_id
ORDER BY total_cost_gbp DESC;

SELECT * FROM finops.pipeline_by_user;
