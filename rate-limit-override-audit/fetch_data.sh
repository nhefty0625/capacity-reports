#!/bin/bash

# Data Fetching Script for Rate Limit Override Audit
# Pulls elevated rate limits + HVAPI subscription data from Snowflake

set -e

mkdir -p data

CONN="--connection global"

echo "========================================="
echo "Fetching Rate Limit Override Audit Data from Snowflake"
echo "========================================="
echo ""

# 1. Fetch accounts with elevated rate limits (any category above default)
echo "[1/2] Fetching accounts with elevated rate limits..."
snow sql -q "
WITH latest AS (
    SELECT
        INSTANCE_ACCOUNT_ID,
        INSTANCE_ACCOUNT_SUBDOMAIN,
        INSTANCE_ACCOUNT_POD_ID,
        SUBSCRIPTION_RATE_LIMIT,
        TICKETS_UPDATE_LIMIT,
        PER_TICKET_UPDATES_LIMIT,
        INFLIGHT_JOBS_LIMIT,
        INCREMENTAL_EXPORTS_LIMIT,
        SUBSCRIPTION_RATE_USED,
        TICKETS_UPDATE_USED,
        ERRORS_429_COUNT,
        ROW_NUMBER() OVER (PARTITION BY INSTANCE_ACCOUNT_ID ORDER BY API_CALL_DATE DESC) AS rn
    FROM PROPAGATED_PRESENTATION.SRE_CAPACITY.FACT_CAPACITY_AGGREGATED_API_USAGE_DATA_DAILY_SNAPSHOT
    WHERE API_CALL_DATE >= CURRENT_DATE() - 7
)
SELECT
    INSTANCE_ACCOUNT_ID,
    INSTANCE_ACCOUNT_SUBDOMAIN,
    INSTANCE_ACCOUNT_POD_ID,
    SUBSCRIPTION_RATE_LIMIT,
    TICKETS_UPDATE_LIMIT,
    PER_TICKET_UPDATES_LIMIT,
    INFLIGHT_JOBS_LIMIT,
    INCREMENTAL_EXPORTS_LIMIT,
    SUBSCRIPTION_RATE_USED,
    TICKETS_UPDATE_USED,
    ERRORS_429_COUNT
FROM latest
WHERE rn = 1
  AND INSTANCE_ACCOUNT_SUBDOMAIN NOT LIKE 'z3n%'
  AND (
    SUBSCRIPTION_RATE_LIMIT > 700
    OR TICKETS_UPDATE_LIMIT > 100
    OR PER_TICKET_UPDATES_LIMIT > 30
    OR INFLIGHT_JOBS_LIMIT > 30
    OR INCREMENTAL_EXPORTS_LIMIT > 30
  )
" $CONN --format CSV > data/elevated_accounts.csv
if [ -f data/elevated_accounts.csv ]; then
    line_count=$(wc -l < data/elevated_accounts.csv)
    echo "  elevated_accounts.csv - $line_count rows (including header)"
fi
echo ""

# 2. Fetch HVAPI subscription status from DIM_INSTANCE_PRODUCTS
echo "[2/2] Fetching HVAPI and plan tier data..."
snow sql -q "
SELECT
    p.INSTANCE_ACCOUNT_ID,
    p.PRODUCT_NAME,
    p.PRODUCT_STATE,
    p.PLAN_TYPE_NAME
FROM FOUNDATIONAL.CUSTOMER.DIM_INSTANCE_PRODUCTS_DAILY_SNAPSHOT p
WHERE p.RUN_DATE = CURRENT_DATE()
  AND (
    (p.PRODUCT_NAME = 'high_volume_api' AND p.PRODUCT_STATE = 'subscribed')
    OR (p.PRODUCT_NAME = 'support' AND p.PRODUCT_STATE = 'subscribed')
  )
  AND p.INSTANCE_ACCOUNT_ID IN (
    SELECT DISTINCT INSTANCE_ACCOUNT_ID
    FROM PROPAGATED_PRESENTATION.SRE_CAPACITY.FACT_CAPACITY_AGGREGATED_API_USAGE_DATA_DAILY_SNAPSHOT
    WHERE API_CALL_DATE >= CURRENT_DATE() - 7
      AND INSTANCE_ACCOUNT_SUBDOMAIN NOT LIKE 'z3n%'
      AND (
        SUBSCRIPTION_RATE_LIMIT > 700
        OR TICKETS_UPDATE_LIMIT > 100
        OR PER_TICKET_UPDATES_LIMIT > 30
        OR INFLIGHT_JOBS_LIMIT > 30
        OR INCREMENTAL_EXPORTS_LIMIT > 30
      )
  )
" $CONN --format CSV > data/product_features.csv
if [ -f data/product_features.csv ]; then
    line_count=$(wc -l < data/product_features.csv)
    echo "  product_features.csv - $line_count rows (including header)"
fi
echo ""

# 3. Fetch ARR and agent count
echo "[3/5] Fetching ARR and agent counts..."
snow sql -q "
SELECT
    o.ACCOUNTID AS INSTANCE_ACCOUNT_ID,
    o.ARR,
    p.MAX_AGENTS AS AGENT_COUNT
FROM FOUNDATIONAL.CAM_ALL_ACCOUNT_OVERVIEW.ALL_ACCOUNTS_OVERVIEW o
LEFT JOIN FOUNDATIONAL.CUSTOMER.DIM_INSTANCE_PRODUCTS_DAILY_SNAPSHOT p
    ON o.ACCOUNTID = p.INSTANCE_ACCOUNT_ID
    AND p.RUN_DATE = CURRENT_DATE()
    AND p.PRODUCT_NAME = 'support'
    AND p.PRODUCT_STATE = 'subscribed'
WHERE o.ACCOUNTID IN (
    SELECT DISTINCT INSTANCE_ACCOUNT_ID
    FROM PROPAGATED_PRESENTATION.SRE_CAPACITY.FACT_CAPACITY_AGGREGATED_API_USAGE_DATA_DAILY_SNAPSHOT
    WHERE API_CALL_DATE >= CURRENT_DATE() - 7
      AND INSTANCE_ACCOUNT_SUBDOMAIN NOT LIKE 'z3n%'
      AND (
        SUBSCRIPTION_RATE_LIMIT > 700
        OR TICKETS_UPDATE_LIMIT > 100
        OR PER_TICKET_UPDATES_LIMIT > 30
        OR INFLIGHT_JOBS_LIMIT > 30
        OR INCREMENTAL_EXPORTS_LIMIT > 30
      )
  )
" $CONN --format CSV > data/arr_agents.csv
if [ -f data/arr_agents.csv ]; then
    line_count=$(wc -l < data/arr_agents.csv)
    echo "  arr_agents.csv - $line_count rows (including header)"
fi
echo ""

# 4. Fetch contract renewal dates from Zuora
echo "[4/5] Fetching contract renewal dates..."
snow sql -q "
SELECT
    m.INSTANCE_ACCOUNT_ID,
    MAX(z.LAST_SUBSCRIPTION_TERM_END_DATE) AS CONTRACT_RENEWAL_DATE
FROM FOUNDATIONAL.FINANCE.DIM_ZUORA_SUBSCRIPTION_RATE_PLAN_CHARGES_BCV z
JOIN FOUNDATIONAL.CUSTOMER_STAGING.INT_ZUORA_ACCOUNT_ID_MAPPINGS m
    ON z.ACCOUNT_ID = m.BILLING_ACCOUNT_ID
    AND m.RUN_DATE = CURRENT_DATE()
WHERE z.LAST_SUBSCRIPTION_TERM_END_DATE IS NOT NULL
  AND z.LAST_SUBSCRIPTION_TERM_END_DATE >= CURRENT_DATE()
  AND m.INSTANCE_ACCOUNT_ID IN (
    SELECT DISTINCT INSTANCE_ACCOUNT_ID
    FROM PROPAGATED_PRESENTATION.SRE_CAPACITY.FACT_CAPACITY_AGGREGATED_API_USAGE_DATA_DAILY_SNAPSHOT
    WHERE API_CALL_DATE >= CURRENT_DATE() - 7
      AND INSTANCE_ACCOUNT_SUBDOMAIN NOT LIKE 'z3n%'
      AND (
        SUBSCRIPTION_RATE_LIMIT > 700
        OR TICKETS_UPDATE_LIMIT > 100
        OR PER_TICKET_UPDATES_LIMIT > 30
        OR INFLIGHT_JOBS_LIMIT > 30
        OR INCREMENTAL_EXPORTS_LIMIT > 30
      )
  )
GROUP BY m.INSTANCE_ACCOUNT_ID
" $CONN --format CSV > data/renewal_dates.csv
if [ -f data/renewal_dates.csv ]; then
    line_count=$(wc -l < data/renewal_dates.csv)
    echo "  renewal_dates.csv - $line_count rows (including header)"
fi
echo ""

# 5. Fetch sandbox status for elevated accounts
echo "[5/5] Fetching sandbox account flags..."
snow sql -q "
SELECT DISTINCT
    a.INSTANCE_ACCOUNT_ID,
    a.INSTANCE_ACCOUNT_SANDBOX_MASTER_ID
FROM PROPAGATED_CLEANSED.PRODUCT_ACCOUNTS.BASE_INSTANCE_ACCOUNTS a
WHERE a.INSTANCE_ACCOUNT_SANDBOX_MASTER_ID IS NOT NULL
  AND a.ZDP_META_IS_DELETED = false
  AND a.INSTANCE_ACCOUNT_ID IN (
    SELECT DISTINCT INSTANCE_ACCOUNT_ID
    FROM PROPAGATED_PRESENTATION.SRE_CAPACITY.FACT_CAPACITY_AGGREGATED_API_USAGE_DATA_DAILY_SNAPSHOT
    WHERE API_CALL_DATE >= CURRENT_DATE() - 7
      AND INSTANCE_ACCOUNT_SUBDOMAIN NOT LIKE 'z3n%'
      AND (
        SUBSCRIPTION_RATE_LIMIT > 700
        OR TICKETS_UPDATE_LIMIT > 100
        OR PER_TICKET_UPDATES_LIMIT > 30
        OR INFLIGHT_JOBS_LIMIT > 30
        OR INCREMENTAL_EXPORTS_LIMIT > 30
      )
  )
" $CONN --format CSV > data/sandbox_accounts.csv
if [ -f data/sandbox_accounts.csv ]; then
    line_count=$(wc -l < data/sandbox_accounts.csv)
    echo "  sandbox_accounts.csv - $line_count rows (including header)"
fi
echo ""

echo "========================================="
echo "Data fetch complete!"
echo "========================================="
echo ""
echo "CSV files saved to data/:"
ls -lh data/*.csv
echo ""
echo "Ready for analysis. Run ./run_analysis.sh next."
