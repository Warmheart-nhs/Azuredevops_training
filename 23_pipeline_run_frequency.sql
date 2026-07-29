/******************************************************************************
Project     : Azure Databricks FinOps Accelerator
Script      : 23_pipeline_run_frequency.sql
Purpose     : Turns pipeline_daily_cost into a per-pipeline efficiency view
              that answers the question data engineers actually care about:
              "How many times does my pipeline run per day, what does each
              run cost, and how much would I save by running it less often?"
Business    : avg_runs_per_day tells an engineer how frequently their
              pipeline is scheduled. avg_cost_per_run_gbp tells them the
              price of each one of those runs. annual_cost_per_daily_run_gbp
              answers "what does keeping ONE run/day in the schedule cost
              me over a year" — the number to weigh against the business
              need for that run frequency (e.g. near-real-time freshness)
              before deciding whether to consolidate/reduce runs.
Run Order   : 23rd (after 14_pipeline_daily_cost.sql)
******************************************************************************/

USE finops;

CREATE OR REPLACE VIEW finops.pipeline_run_frequency AS
SELECT
    pipeline_id,
    COUNT(DISTINCT usage_date)                              AS active_days,
    SUM(runs)                                               AS total_runs,
    ROUND(SUM(runs) / COUNT(DISTINCT usage_date), 1)        AS avg_runs_per_day,
    MAX(runs)                                               AS max_runs_in_a_day,
    ROUND(SUM(daily_cost_gbp), 2)                           AS total_cost_gbp,
    ROUND(SUM(daily_cost_gbp) / SUM(runs), 2)               AS avg_cost_per_run_gbp,
    ROUND(SUM(daily_cost_gbp) / COUNT(DISTINCT usage_date), 2)
                                                             AS avg_daily_cost_gbp,
    -- The cost of keeping ONE run/day in this pipeline's schedule for a year.
    -- Multiply by the number of runs/day you're considering cutting to get
    -- the annualised saving.
    ROUND((SUM(daily_cost_gbp) / SUM(runs)) * 365, 2)       AS annual_cost_per_daily_run_gbp
FROM finops.pipeline_daily_cost
GROUP BY pipeline_id
ORDER BY total_cost_gbp DESC;

SELECT * FROM finops.pipeline_run_frequency;
