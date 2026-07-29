/******************************************************************************
Project     : Azure Databricks FinOps Accelerator
Script      : 00_deploy_all.sql
Purpose     : Reference index of deployment order. Databricks SQL does not
              support file-based `source`/`include` in production notebooks,
              so run each numbered file in this folder IN ORDER via a
              Databricks Notebook (%sql cell per file) or the Databricks
              SQL / Workflows "Run SQL file" task. Do not skip a step.

  01_create_finops_schema.sql          - create finops schema
  02_validate_system_tables.sql        - confirm billing system tables exist
  03_create_reference_tables.sql       - exchange rate + monthly_budget
  04_create_master_billing_view.sql    - billing_master (everything reads this)
  05_validate_master_billing_view.sql  - sanity checks
  06_daily_cost_report.sql             - finops.daily_cost
  07_weekly_cost_report.sql            - finops.weekly_cost
  08_monthly_cost_report.sql           - finops.monthly_cost
  09_executive_summary.sql             - finops.executive_summary
  10_executive_kpi_dataset.sql         - finops.executive_kpis
  11_cost_trend_report.sql             - finops.cost_trend
  12_budget_vs_actual.sql              - finops.budget_vs_actual (needs 03 + 08)
  13_top10_pipelines.sql               - finops.top10_pipelines
  14_pipeline_daily_cost.sql           - finops.pipeline_daily_cost
  15_pipeline_weekly_cost.sql          - finops.pipeline_weekly_cost
  16_pipeline_monthly_cost.sql         - finops.pipeline_monthly_cost
  17_pipeline_by_user.sql              - finops.pipeline_by_user
  18_pipeline_runtime.sql              - finops.pipeline_runtime
  19_pipeline_success_rate.sql         - finops.pipeline_success_rate (placeholder)
  20_top10_jobs.sql                    - finops.top10_jobs
  21_job_daily_cost.sql                - finops.job_daily_cost
  22_job_by_user.sql                   - finops.job_by_user
  23_pipeline_run_frequency.sql        - finops.pipeline_run_frequency (needs 14)
  24_job_run_frequency.sql             - finops.job_run_frequency (needs 21)

Re-running is safe: schema/table creation uses IF NOT EXISTS, views use
CREATE OR REPLACE, and the reference table inserts are idempotent.

------------------------------------------------------------------------------
Target platform: Azure Databricks Runtime 17.3 LTS (Spark 4.0, ANSI SQL
default). Two fixes were applied specifically for this version and are
already baked into the files above — nothing further to change:

  1. 04_create_master_billing_view.sql casts pricing.default to DECIMAL
     before multiplying by usage_quantity. DBR 17.x disallows implicit
     DECIMAL * DOUBLE arithmetic under ANSI SQL, which is the default here.
  2. Every view that reads pipeline identity now uses
     usage_metadata.dlt_pipeline_id (not usage_metadata.pipeline_id) —
     the current system.billing.usage schema field name. Output columns are
     still aliased to `pipeline_id`, so nothing downstream (app/ or
     dashboard/) needed to change.
------------------------------------------------------------------------------

To re-run everything from a Databricks Notebook, put each file's contents in
its own cell in this order, or run:

    %run ./01_create_finops_schema
    %run ./02_validate_system_tables
    ... etc

(if you convert these .sql files to notebooks first).
******************************************************************************/

SELECT 'See file header for deployment order — run 01 through 20 in sequence.' AS instructions;
