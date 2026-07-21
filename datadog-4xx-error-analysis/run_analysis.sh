#!/bin/bash

# Datadog 4XX Error Analysis Pipeline Runner
# Analyze 4XX errors by subdomain to identify problematic integrations and workflows

set -e

DB_FILE="analysis.duckdb"

echo "========================================="
echo "Datadog 4XX Error Analysis Pipeline"
echo "========================================="
echo ""
echo "Database: $DB_FILE"
echo ""

# Check if data files exist
echo "Checking data files..."
if ! ls data/*_status_codes.json 1>/dev/null 2>&1; then
    echo "ERROR: No data files found in data/"
    echo ""
    echo "Run ./fetch_data.sh first to fetch data from Datadog."
    exit 1
fi
echo "Data files present"
echo ""

# Remove existing database to start fresh
rm -f "$DB_FILE"

# Task 1: Load and standardize
echo "[1/2] Loading and standardizing data..."
duckdb "$DB_FILE" < sql/task_01_load_and_standardize.sql
echo "  Done"
echo ""

# Render Quarto report
echo "[2/2] Rendering Quarto report..."
quarto render datadog-4xx-error-analysis.qmd --output-dir .
echo "  Done"
echo ""

# Copy to docs for GitHub Pages
echo "Copying files to docs for GitHub Pages..."
DOCS_DIR="../docs/datadog-4xx-error-analysis"
mkdir -p "$DOCS_DIR/data"

if [ -f "datadog-4xx-error-analysis.html" ]; then
    rm -f "$DOCS_DIR/datadog-4xx-error-analysis.html"
    cp datadog-4xx-error-analysis.html "$DOCS_DIR/"
    echo "  $DOCS_DIR/datadog-4xx-error-analysis.html"
fi

for csv in data/agg_*.csv; do
    if [ -f "$csv" ]; then
        cp "$csv" "$DOCS_DIR/data/"
        echo "  $DOCS_DIR/$csv"
    fi
done
echo ""

echo "========================================="
echo "Analysis Complete!"
echo "========================================="
echo ""
echo "Report: datadog-4xx-error-analysis.html"
echo ""
echo "To explore results interactively:"
echo "  duckdb $DB_FILE"
