/******************************************************************************
Project     : Azure Databricks FinOps Accelerator
Script      : 24_job_run_frequency.sql
Purpose     : Job-level equivalent of 23_pipeline_run_frequency.sql — same
              run-frequency-vs-cost reasoning, applied to Databricks Jobs.
Run Order   : 24th (after 21_job_daily_cost.sql)
******************************************************************************/

USE finops;

CREATE OR REPLACE VIEW finops.job_run_frequency AS
SELECT
    job_id,
    COUNT(DISTINCT usage_date)                              AS active_days,
    SUM(runs)                                               AS total_runs,
    ROUND(SUM(runs) / COUNT(DISTINCT usage_date), 1)        AS avg_runs_per_day,
    MAX(runs)                                               AS max_runs_in_a_day,
    ROUND(SUM(daily_cost_gbp), 2)                           AS total_cost_gbp,
    ROUND(SUM(daily_cost_gbp) / SUM(runs), 2)               AS avg_cost_per_run_gbp,
    ROUND(SUM(daily_cost_gbp) / COUNT(DISTINCT usage_date), 2)
                                                             AS avg_daily_cost_gbp,
    ROUND((SUM(daily_cost_gbp) / SUM(runs)) * 365, 2)       AS annual_cost_per_daily_run_gbp
FROM finops.job_daily_cost
GROUP BY job_id
ORDER BY total_cost_gbp DESC;

SELECT * FROM finops.job_run_frequency;
