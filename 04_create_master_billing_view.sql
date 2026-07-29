/******************************************************************************
Project     : Azure Databricks FinOps Accelerator
Script      : 04_create_master_billing_view.sql
Purpose     : Creates the Master Billing View that every downstream report
              reads from. Joins Billing Usage + List Prices + Exchange Rate
              and calculates cost in USD and GBP.
Run Order   : 4th (after 03_create_reference_tables.sql)

DBR 17.3 LTS note
------------------------------------------------------------------------------
DBR 17.x (Spark 4.0) defaults to ANSI SQL and disallows implicit
multiplication between DECIMAL and DOUBLE/FLOAT operands. usage_quantity is
DECIMAL but pricing.default in system.billing.list_prices is DOUBLE, so the
raw expression `usage_quantity * pricing.default` fails under ANSI. Casting
pricing.default to DECIMAL first avoids that error and, as a side benefit,
keeps every downstream cost calculation in fixed-point DECIMAL instead of
floating-point DOUBLE, which is the correct choice for money.
******************************************************************************/

USE finops;

CREATE OR REPLACE VIEW finops.billing_master AS
SELECT
    u.account_id,
    u.workspace_id,
    u.usage_date,
    u.usage_start_time,
    u.usage_end_time,
    u.sku_name,
    u.cloud,
    u.usage_quantity,
    u.usage_unit,
    u.usage_metadata,
    u.identity_metadata,
    u.custom_tags,
    CAST(p.pricing.default AS DECIMAL(20,10)) AS unit_price_usd,
    ROUND(u.usage_quantity * CAST(p.pricing.default AS DECIMAL(20,10)), 2) AS total_cost_usd,
    ROUND(u.usage_quantity * CAST(p.pricing.default AS DECIMAL(20,10)) * e.exchange_rate, 2) AS total_cost_gbp
FROM system.billing.usage u
INNER JOIN system.billing.list_prices p
    ON u.sku_name = p.sku_name
    AND u.usage_start_time BETWEEN p.price_start_time
        AND COALESCE(p.price_end_time, CURRENT_TIMESTAMP())
CROSS JOIN finops.reference_exchange_rate e;
