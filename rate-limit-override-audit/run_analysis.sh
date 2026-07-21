#!/bin/bash

# Rate Limit Override Audit Pipeline Runner
# Classify accounts by concern level and generate report

set -e

DB_FILE="analysis.duckdb"

echo "========================================="
echo "Rate Limit Override Audit Analysis Pipeline"
echo "========================================="
echo ""
echo "Database: $DB_FILE"
echo ""

# Check if data files exist
echo "Checking data files..."
required_files=(
    "data/elevated_accounts.csv"
    "data/product_features.csv"
    "data/renewal_dates.csv"
    "data/sandbox_accounts.csv"
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

# Task 1: Load and classify
echo "[1/2] Loading and classifying accounts..."
duckdb "$DB_FILE" < sql/task_01_load_and_classify.sql
echo "  Done"
echo ""

# Task 2: Render Quarto report
echo "[2/2] Rendering Quarto report..."
quarto render rate-limit-override-audit.qmd --output-dir .
echo "  Done"
echo ""

# Copy to docs for GitHub Pages
echo "Copying files to docs for GitHub Pages..."
DOCS_DIR="../docs/rate-limit-override-audit"
mkdir -p "$DOCS_DIR/data"

if [ -f "rate-limit-override-audit.html" ]; then
    rm -f "$DOCS_DIR/rate-limit-override-audit.html"
    cp rate-limit-override-audit.html "$DOCS_DIR/"
    echo "  $DOCS_DIR/rate-limit-override-audit.html"
fi

for csv in data/agg_*.csv data/high_concern.csv data/medium_concern.csv data/sandbox_elevated.csv; do
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
echo "Report: rate-limit-override-audit.html"
echo ""
echo "Key outputs:"
echo "  data/high_concern.csv   - Accounts above HVAPI limits"
echo "  data/medium_concern.csv - HVAPI-level without addon"
echo "  data/agg_concern_summary.csv - Summary by tier"
echo ""
echo "To explore results interactively:"
echo "  duckdb $DB_FILE"
