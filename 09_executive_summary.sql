/******************************************************************************
Project     : Azure Databricks FinOps Accelerator
Script      : 09_executive_summary.sql
Purpose     : Creates a single Executive Summary View used by the management
              dashboard: today's spend, weekly spend, monthly spend, totals.
Run Order   : 9th
******************************************************************************/

USE finops;

CREATE OR REPLACE VIEW finops.executive_summary AS
SELECT
    ROUND(SUM(total_cost_gbp), 2) AS total_spend_gbp,

    ROUND(SUM(CASE WHEN usage_date = CURRENT_DATE()
                    THEN total_cost_gbp ELSE 0 END), 2) AS today_spend_gbp,

    ROUND(SUM(CASE WHEN usage_date >= DATE_SUB(CURRENT_DATE(), 7)
                    THEN total_cost_gbp ELSE 0 END), 2) AS weekly_spend_gbp,

    ROUND(SUM(CASE WHEN YEAR(usage_date) = YEAR(CURRENT_DATE())
                    AND MONTH(usage_date) = MONTH(CURRENT_DATE())
                    THEN total_cost_gbp ELSE 0 END), 2) AS monthly_spend_gbp,

    COUNT(DISTINCT workspace_id)               AS total_workspaces,
    COUNT(DISTINCT usage_metadata.dlt_pipeline_id) AS total_pipelines,
    COUNT(DISTINCT usage_metadata.job_id)      AS total_jobs,
    COUNT(DISTINCT identity_metadata.run_as)   AS total_users
FROM finops.billing_master;

SELECT * FROM finops.executive_summary;
