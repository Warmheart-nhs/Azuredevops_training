/******************************************************************************
Project     : Azure Databricks FinOps Accelerator
Script      : 02_validate_system_tables.sql
Purpose     : Confirms the Databricks billing system tables required for
              cost reporting are available before any views are built.
Run Order   : 2nd (after 01_create_finops_schema.sql)
******************************************************************************/

SELECT COUNT(*) AS billing_usage_records FROM system.billing.usage;

DESCRIBE TABLE system.billing.usage;

SELECT * FROM system.billing.usage LIMIT 10;

SELECT COUNT(*) AS list_price_records FROM system.billing.list_prices;

SELECT * FROM system.billing.list_prices LIMIT 10;

SELECT
    'System Tables Successfully Validated' AS validation_status,
    current_timestamp()                    AS validation_time;
