/******************************************************************************
Project     : Azure Databricks FinOps Accelerator
Script      : 19_pipeline_success_rate.sql
Purpose     : Placeholder for Pipeline Success Rate.
Note        : Success/failure status is NOT available in the billing system
              table. This view prepares the structure and should later be
              joined to system.lakeflow.job_run_timeline or the Jobs API.
Run Order   : 19th
******************************************************************************/

USE finops;

CREATE OR REPLACE VIEW finops.pipeline_success_rate AS
SELECT
    usage_metadata.dlt_pipeline_id AS pipeline_id,
    COUNT(*) AS executions,
    'Requires Lakeflow System Tables' AS status_source
FROM finops.billing_master
WHERE usage_metadata.dlt_pipeline_id IS NOT NULL
GROUP BY usage_metadata.dlt_pipeline_id;

SELECT * FROM finops.pipeline_success_rate;
