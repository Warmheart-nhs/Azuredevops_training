/******************************************************************************
Project     : Azure Databricks FinOps Accelerator
Script      : 16_pipeline_monthly_cost.sql
Purpose     : Monthly Pipeline Cost report.
Run Order   : 16th
******************************************************************************/

USE finops;

CREATE OR REPLACE VIEW finops.pipeline_monthly_cost AS
SELECT
    YEAR(usage_date)  AS usage_year,
    MONTH(usage_date) AS usage_month,
    DATE_FORMAT(usage_date, 'MMMM yyyy') AS reporting_month,
    usage_metadata.dlt_pipeline_id AS pipeline_id,
    COUNT(*)                       AS total_runs,
    ROUND(SUM(total_cost_gbp), 2) AS monthly_cost_gbp,
    ROUND(AVG(total_cost_gbp), 2) AS average_run_cost_gbp
FROM finops.billing_master
WHERE usage_metadata.dlt_pipeline_id IS NOT NULL
GROUP BY YEAR(usage_date), MONTH(usage_date), DATE_FORMAT(usage_date, 'MMMM yyyy'),
         usage_metadata.dlt_pipeline_id
ORDER BY usage_year DESC, usage_month DESC, monthly_cost_gbp DESC;

SELECT * FROM finops.pipeline_monthly_cost LIMIT 20;
