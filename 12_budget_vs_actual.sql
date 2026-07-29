/******************************************************************************
Project     : Azure Databricks FinOps Accelerator
Script      : 12_budget_vs_actual.sql
Purpose     : Budget vs Actual report. Depends on finops.monthly_budget,
              which is created/seeded in 03_create_reference_tables.sql.
Run Order   : 12th
******************************************************************************/

USE finops;

CREATE OR REPLACE VIEW finops.budget_vs_actual AS
SELECT
    b.budget_month,
    b.budget_gbp,
    ROUND(m.monthly_cost_gbp, 2) AS actual_cost_gbp,
    ROUND(b.budget_gbp - m.monthly_cost_gbp, 2) AS remaining_budget_gbp,
    ROUND((m.monthly_cost_gbp / NULLIF(b.budget_gbp, 0)) * 100, 1) AS pct_of_budget_used
FROM finops.monthly_budget b
LEFT JOIN finops.monthly_cost m
    ON DATE_FORMAT(m.month_start, 'yyyy-MM') = b.budget_month;

SELECT * FROM finops.budget_vs_actual;
