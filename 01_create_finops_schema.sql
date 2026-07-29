/******************************************************************************
Project     : Azure Databricks FinOps Accelerator
Script      : 01_create_finops_schema.sql
Purpose     : Creates the FINOPS schema that holds every reporting object
              used throughout this project, isolated from production data.
Dependencies: Unity Catalog enabled
Run Order   : 1st
******************************************************************************/

SELECT current_catalog();
SELECT current_schema();

CREATE SCHEMA IF NOT EXISTS finops;

USE finops;

SHOW TABLES;

SELECT
    'FINOPS Schema Successfully Created' AS status,
    current_catalog()                    AS catalog_name,
    current_schema()                     AS schema_name,
    current_timestamp()                  AS execution_time;
