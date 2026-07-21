#!/bin/bash

# Customer Rate Limit Report Pipeline Runner
# Analyze customer rate limiting patterns and trends

set -e

DB_FILE="analysis.duckdb"

echo "========================================="
echo "Customer Rate Limit Report Analysis Pipeline"
echo "========================================="
echo ""
echo "Database: $DB_FILE"
echo ""

# Check if data files exist
echo "Checking data files..."
required_files=(
    "data/rate_limited_customers.csv"
)

missing_files=()
for file in "${required_files[@]}"; do
    if [ ! -f "$file" ]; then
        missing_files+=("$file")
    fi
done

if [ ${#missing_files[@]} -gt 0 ]; then
    echo "ERROR: Missing required data files:"
    for file in "${missing_files[@]}"; do
        echo "  - $file"
    done
    echo ""
    echo "Run ./fetch_data.sh first to fetch data from Snowflake."
    exit 1
fi
echo "All data files present"
echo ""

# Remove existing database to start fresh
rm -f "$DB_FILE"

# Task 1: Load and standardize
echo "[1/N] Loading and standardizing data..."
duckdb "$DB_FILE" < sql/task_01_load_and_standardize.sql
echo "  Done"
echo ""

# Render Quarto report
echo "[N/N] Rendering Quarto report..."
quarto render customer-rate-limit-report.qmd --output-dir .
echo "  Done"
echo ""

# Copy to docs for GitHub Pages
echo "Copying files to docs for GitHub Pages..."
DOCS_DIR="../docs/customer-rate-limit-report"
mkdir -p "$DOCS_DIR/data"

if [ -f "customer-rate-limit-report.html" ]; then
    rm -f "$DOCS_DIR/customer-rate-limit-report.html"
    cp customer-rate-limit-report.html "$DOCS_DIR/"
    echo "  $DOCS_DIR/customer-rate-limit-report.html"
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
echo "Report: customer-rate-limit-report.html"
echo ""
echo "To explore results interactively:"
echo "  duckdb $DB_FILE"
