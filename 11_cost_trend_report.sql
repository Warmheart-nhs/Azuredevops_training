/******************************************************************************
Project     : Azure Databricks FinOps Accelerator
Script      : 11_cost_trend_report.sql
Purpose     : Creates the Cost Trend dataset (daily cost + running total)
              used for trend-line charts.
Run Order   : 11th
******************************************************************************/

USE finops;

CREATE OR REPLACE VIEW finops.cost_trend AS
SELECT
    usage_date,
    ROUND(SUM(total_cost_gbp), 2) AS daily_cost,
    SUM(SUM(total_cost_gbp)) OVER (
        ORDER BY usage_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total
FROM finops.billing_master
GROUP BY usage_date
ORDER BY usage_date;

SELECT * FROM finops.cost_trend ORDER BY usage_date DESC;
