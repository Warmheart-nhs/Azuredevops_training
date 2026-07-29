/******************************************************************************
Project     : Azure Databricks FinOps Accelerator
Script      : 03_create_reference_tables.sql
Purpose     : Creates all reference tables used throughout the project.
              Reference tables hold static/slow-changing business data that
              Finance maintains independently of the billing pipeline.
Run Order   : 3rd (after 02_validate_system_tables.sql)

Tables created:
  1. finops.reference_exchange_rate  - USD -> GBP conversion rate
  2. finops.monthly_budget           - Approved monthly budget per month,
                                       required by 12_budget_vs_actual.sql
                                       (this table was referenced but never
                                       defined in the original script set —
                                       added here to close that gap)
******************************************************************************/

USE finops;

-- ============================================================================
-- Exchange Rate reference table
-- Finance updates this whenever the approved USD->GBP rate changes.
-- ============================================================================

CREATE TABLE IF NOT EXISTS finops.reference_exchange_rate
(
    currency_code       STRING,
    exchange_rate       DECIMAL(10,4),
    effective_date       DATE,
    created_timestamp   TIMESTAMP
);

DELETE FROM finops.reference_exchange_rate;

INSERT INTO finops.reference_exchange_rate
VALUES
(
    'GBP',
    0.7400,
    CURRENT_DATE(),
    CURRENT_TIMESTAMP()
);

SELECT * FROM finops.reference_exchange_rate;

-- ============================================================================
-- Monthly Budget reference table
-- Finance maintains one row per calendar month (format 'yyyy-MM').
-- Populate/update this table manually or via a scheduled load whenever a new
-- budget is approved. budget_vs_actual.sql joins on budget_month.
-- ============================================================================

CREATE TABLE IF NOT EXISTS finops.monthly_budget
(
    budget_month        STRING,   -- format 'yyyy-MM', e.g. '2026-07'
    budget_gbp           DECIMAL(12,2),
    approved_by          STRING,
    created_timestamp   TIMESTAMP
);

-- Example seed row — replace with your actual approved budget(s).
-- Safe to re-run: only inserts if this month has no budget row yet.
INSERT INTO finops.monthly_budget
SELECT
    DATE_FORMAT(CURRENT_DATE(), 'yyyy-MM'),
    10000.00,
    'Finance',
    CURRENT_TIMESTAMP()
WHERE NOT EXISTS (
    SELECT 1 FROM finops.monthly_budget
    WHERE budget_month = DATE_FORMAT(CURRENT_DATE(), 'yyyy-MM')
);

SELECT * FROM finops.monthly_budget;
