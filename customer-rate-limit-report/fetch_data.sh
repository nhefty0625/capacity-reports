#!/bin/bash

# Data Fetching Script for Customer Rate Limit Report
# Fetch customer rate limiting data from Snowflake

set -e

mkdir -p data

echo "========================================="
echo "Fetching Customer Rate Limit Report Data from Snowflake"
echo "========================================="
echo ""

# 1. Fetch rate-limited customers (top 429 error row per account)
echo "[1/1] Fetching rate-limited customer data..."
snow sql -q "
WITH filtered_data AS (
    SELECT
        b.instance_account_id,
        b.instance_account_name,
        b.created_timestamp,
        f.tickets_update_limit,
        f.tickets_update_used,
        f.errors_429_count
    FROM
        PROPAGATED_PRESENTATION.SRE_CAPACITY.FACT_CAPACITY_AGGREGATED_API_USAGE_DATA_DAILY_SNAPSHOT f
    JOIN
        PROPAGATED_CLEANSED.PRODUCT_ACCOUNTS.BASE_INSTANCE_ACCOUNTS b
        ON f.instance_account_id = b.instance_account_id
    WHERE
        b.created_timestamp < '2019-07-01 00:00:00.000'
        AND f.tickets_update_limit < 5000
        AND f.tickets_update_used > 300
        AND f.errors_429_count > 0
)
SELECT
    instance_account_id,
    instance_account_name,
    created_timestamp,
    tickets_update_limit,
    tickets_update_used,
    errors_429_count
FROM (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY instance_account_id ORDER BY errors_429_count DESC) AS rn
    FROM filtered_data
) ranked
WHERE rn = 1
" --format CSV > data/rate_limited_customers.csv
if [ -f data/rate_limited_customers.csv ]; then
    line_count=$(wc -l < data/rate_limited_customers.csv)
    echo "  rate_limited_customers.csv - $line_count rows (including header)"
fi
echo ""

echo "========================================="
echo "Data fetch complete!"
echo "========================================="
echo ""
echo "CSV files saved to data/:"
ls -lh data/*.csv
echo ""
echo "Ready for analysis."
