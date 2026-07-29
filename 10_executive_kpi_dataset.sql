/******************************************************************************
Project     : Azure Databricks FinOps Accelerator
Script      : 10_executive_kpi_dataset.sql
Purpose     : Creates a long/narrow KPI dataset (kpi, kpi_value) for driving
              dashboard KPI cards directly off a single view.
Run Order   : 10th

Note: the value column is named kpi_value rather than the bare word VALUE —
VALUE is reserved in some ANSI SQL contexts (e.g. TABLE(VALUES ...)), and
DBR 17.x defaults to ANSI SQL, so this avoids any ambiguity.
******************************************************************************/

USE finops;

CREATE OR REPLACE VIEW finops.executive_kpis AS
SELECT 'Total Spend (GBP)' AS kpi, ROUND(SUM(total_cost_gbp), 2) AS kpi_value
FROM finops.billing_master
UNION ALL
SELECT 'Today Spend (GBP)', ROUND(SUM(total_cost_gbp), 2)
FROM finops.billing_master
WHERE usage_date = CURRENT_DATE()
UNION ALL
SELECT 'Weekly Spend (GBP)', ROUND(SUM(total_cost_gbp), 2)
FROM finops.billing_master
WHERE usage_date >= DATE_SUB(CURRENT_DATE(), 7)
UNION ALL
SELECT 'Monthly Spend (GBP)', ROUND(SUM(total_cost_gbp), 2)
FROM finops.billing_master
WHERE YEAR(usage_date) = YEAR(CURRENT_DATE())
  AND MONTH(usage_date) = MONTH(CURRENT_DATE())
UNION ALL
SELECT 'Total Pipelines', CAST(COUNT(DISTINCT usage_metadata.dlt_pipeline_id) AS DECIMAL(18,2))
FROM finops.billing_master
UNION ALL
SELECT 'Total Jobs', CAST(COUNT(DISTINCT usage_metadata.job_id) AS DECIMAL(18,2))
FROM finops.billing_master
UNION ALL
SELECT 'Total Users', CAST(COUNT(DISTINCT identity_metadata.run_as) AS DECIMAL(18,2))
FROM finops.billing_master;

SELECT * FROM finops.executive_kpis;
