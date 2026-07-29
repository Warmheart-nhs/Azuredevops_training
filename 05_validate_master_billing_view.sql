/******************************************************************************
Project     : Azure Databricks FinOps Accelerator
Script      : 05_validate_master_billing_view.sql
Purpose     : Validates the Master Billing View before building reports.
Run Order   : 5th (after 04_create_master_billing_view.sql)
******************************************************************************/

USE finops;

SELECT COUNT(*) AS total_records FROM billing_master;

SELECT ROUND(SUM(total_cost_gbp), 2) AS total_spend_gbp FROM billing_master;

SELECT MIN(usage_date) AS first_usage_date, MAX(usage_date) AS last_usage_date
FROM billing_master;

SELECT COUNT(*) AS null_cost_records FROM billing_master WHERE total_cost_gbp IS NULL;

SELECT * FROM billing_master LIMIT 20;
