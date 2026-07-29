/******************************************************************************
Project     : Azure Databricks FinOps Accelerator
Script      : 15_pipeline_weekly_cost.sql
Purpose     : Weekly Pipeline Cost report. Engineering managers use this to
              spot weekly spend trends and optimisation opportunities.
Run Order   : 15th
******************************************************************************/

USE finops;

CREATE OR REPLACE VIEW finops.pipeline_weekly_cost AS
SELECT
    YEAR(usage_date)       AS usage_year,
    WEEKOFYEAR(usage_date) AS usage_week,
    MIN(usage_date)        AS week_start,
    MAX(usage_date)        AS week_end,
    usage_metadata.dlt_pipeline_id AS pipeline_id,
    COUNT(*)                       AS total_runs,
    ROUND(SUM(total_cost_gbp), 2) AS weekly_cost_gbp,
    ROUND(AVG(total_cost_gbp), 2) AS average_run_cost_gbp
FROM finops.billing_master
WHERE usage_metadata.dlt_pipeline_id IS NOT NULL
GROUP BY YEAR(usage_date), WEEKOFYEAR(usage_date), usage_metadata.dlt_pipeline_id
ORDER BY usage_year DESC, usage_week DESC, weekly_cost_gbp DESC;

SELECT * FROM finops.pipeline_weekly_cost LIMIT 20;
