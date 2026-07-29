/******************************************************************************
Project     : Azure Databricks FinOps Accelerator
Script      : 18_pipeline_runtime.sql
Purpose     : Estimates pipeline runtime using billing timestamps.
Note        : Billing tables do not contain official runtime metrics; this
              is an estimate using usage_start_time / usage_end_time.
Run Order   : 18th
******************************************************************************/

USE finops;

CREATE OR REPLACE VIEW finops.pipeline_runtime AS
SELECT
    usage_metadata.dlt_pipeline_id AS pipeline_id,
    COUNT(*) AS executions,
    ROUND(AVG(TIMESTAMPDIFF(SECOND, usage_start_time, usage_end_time)) / 60, 2)
        AS average_runtime_minutes,
    ROUND(MAX(TIMESTAMPDIFF(SECOND, usage_start_time, usage_end_time)) / 60, 2)
        AS maximum_runtime_minutes
FROM finops.billing_master
WHERE usage_metadata.dlt_pipeline_id IS NOT NULL
GROUP BY usage_metadata.dlt_pipeline_id
ORDER BY average_runtime_minutes DESC;

SELECT * FROM finops.pipeline_runtime;
