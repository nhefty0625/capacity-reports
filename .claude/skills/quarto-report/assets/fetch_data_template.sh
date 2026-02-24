#!/bin/bash

# Data Fetching Script for PROJECT_TITLE
# DESCRIPTION_OF_WHAT_THIS_FETCHES

set -e

mkdir -p data

echo "========================================="
echo "Fetching PROJECT_TITLE Data from Snowflake"
echo "========================================="
echo ""

# 1. Fetch FIRST_TABLE
echo "[1/N] Fetching FIRST_TABLE..."
snow sql -q 'SELECT * FROM FOUNDATIONAL.SCHEMA.TABLE_NAME;' --format CSV > data/first_table.csv
if [ -f data/first_table.csv ]; then
    line_count=$(wc -l < data/first_table.csv)
    echo "  first_table.csv - $line_count rows (including header)"
fi
echo ""

# 2. Fetch SECOND_TABLE
# For EP_METRICS tables, use the -c itools connection:
# echo "[2/N] Fetching SECOND_TABLE..."
# snow sql -c itools -q "
#   SELECT *
#   FROM FOUNDATIONAL.EP_METRICS.TABLE_NAME
#   WHERE IS_PRODUCTION_PIPELINE = TRUE
#     AND START_TIME >= '2025-01-01'
# " --format CSV > data/second_table.csv

echo "========================================="
echo "Data fetch complete!"
echo "========================================="
echo ""
echo "CSV files saved to data/:"
ls -lh data/*.csv
echo ""
echo "Ready for analysis."
