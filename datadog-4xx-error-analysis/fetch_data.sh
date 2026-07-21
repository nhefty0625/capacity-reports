#!/bin/bash

# Data Fetching Script for Datadog 4XX Error Analysis
# Fetch 4XX error data from Datadog using pup CLI for subdomain analysis

set -e

mkdir -p data

echo "========================================="
echo "Fetching Datadog 4XX Error Analysis Data"
echo "========================================="
echo ""

# This script uses the Datadog pup CLI instead of Snowflake.
# Customize the subdomains and time ranges below.

SUBDOMAINS=("halodoc" "fyidocs")
FROM="2d"

for subdomain in "${SUBDOMAINS[@]}"; do
    echo "[*] Fetching 4XX error breakdown for $subdomain..."

    # Status code breakdown -> CSV
    pup logs aggregate \
        --query "*${subdomain}* @http.status_code:[400 TO 499]" \
        --from "$FROM" \
        --compute 'count' \
        --group-by '@http.status_code' \
        | jq -r '["subdomain","status_code","count"], (.data.buckets[] | ["'"$subdomain"'", (.by."@http.status_code" | tostring), (.computes.c0 | tostring)]) | @csv' \
        > "data/${subdomain}_status_codes.csv"
    echo "  ${subdomain}_status_codes.csv"

    # URL breakdown -> CSV
    pup logs aggregate \
        --query "*${subdomain}* @http.status_code:[400 TO 499]" \
        --from "$FROM" \
        --compute 'count' \
        --group-by '@http.url' \
        --limit 50 \
        | jq -r '["subdomain","url","count"], (.data.buckets[] | ["'"$subdomain"'", .by."@http.url", (.computes.c0 | tostring)]) | @csv' \
        > "data/${subdomain}_urls.csv"
    echo "  ${subdomain}_urls.csv"

    # Method breakdown -> CSV
    pup logs aggregate \
        --query "*${subdomain}* @http.status_code:[400 TO 499]" \
        --from "$FROM" \
        --compute 'count' \
        --group-by '@http.method' \
        | jq -r '["subdomain","method","count"], (.data.buckets[] | ["'"$subdomain"'", .by."@http.method", (.computes.c0 | tostring)]) | @csv' \
        > "data/${subdomain}_methods.csv"
    echo "  ${subdomain}_methods.csv"

    echo ""
done

echo "========================================="
echo "Data fetch complete!"
echo "========================================="
echo ""
echo "JSON files saved to data/:"
ls -lh data/*.csv
echo ""
echo "Ready for analysis."
