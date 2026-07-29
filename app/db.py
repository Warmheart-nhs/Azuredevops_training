"""
Databricks SQL Warehouse connection layer for the FinOps Streamlit app.

Uses the Databricks Apps native auth pattern: databricks.sdk.core.Config()
picks up the app's own service-principal credentials automatically when
running inside a Databricks App, so no token needs to be stored or pasted
anywhere in this codebase.
"""

import os
import streamlit as st
import pandas as pd
from databricks import sql
from databricks.sdk.core import Config

_WAREHOUSE_ID_ENV = "DATABRICKS_WAREHOUSE_ID"


@st.cache_resource
def _config() -> Config:
    return Config()


def _http_path() -> str:
    warehouse_id = os.getenv(_WAREHOUSE_ID_ENV)
    if not warehouse_id:
        raise RuntimeError(
            f"{_WAREHOUSE_ID_ENV} is not set. Attach the SQL warehouse resource "
            "to this Databricks App (see app.yaml) so it can inject this value."
        )
    return f"/sql/1.0/warehouses/{warehouse_id}"


def get_connection():
    cfg = _config()
    return sql.connect(
        server_hostname=cfg.host.replace("https://", "").replace("http://", ""),
        http_path=_http_path(),
        credentials_provider=lambda: cfg.authenticate,
    )


@st.cache_data(ttl=300, show_spinner=False)
def run_query(query: str) -> pd.DataFrame:
    """Runs a read-only query against the finops schema and returns a DataFrame.

    Cached for 5 minutes per unique query string to keep the dashboard snappy
    without hammering the warehouse on every rerun/tab switch.
    """
    with get_connection() as conn:
        with conn.cursor() as cursor:
            cursor.execute(query)
            columns = [c[0] for c in cursor.description]
            rows = cursor.fetchall()
    return pd.DataFrame(rows, columns=columns)
