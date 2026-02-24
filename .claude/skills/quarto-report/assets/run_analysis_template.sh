#!/bin/bash

# PROJECT_TITLE Pipeline Runner
# DESCRIPTION_OF_WHAT_THIS_ANALYZES

set -e

DB_FILE="analysis.duckdb"

echo "========================================="
echo "PROJECT_TITLE Analysis Pipeline"
echo "========================================="
echo ""
echo "Database: $DB_FILE"
echo ""

# Check if data files exist
echo "Checking data files..."
required_files=(
    "data/first_table.csv"
    "data/second_table.csv"
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

# Task 2: Transform
echo "[2/N] Running transformations..."
duckdb "$DB_FILE" < sql/task_02_transform.sql
echo "  Done"
echo ""

# Render Quarto report
echo "[N/N] Rendering Quarto report..."
quarto render report_name.qmd --output-dir .
echo "  Done"
echo ""

# Copy to docs for GitHub Pages
echo "Copying files to docs for GitHub Pages..."
DOCS_DIR="../docs/project-name"
mkdir -p "$DOCS_DIR/data"

if [ -f "report_name.html" ]; then
    rm -f "$DOCS_DIR/report_name.html"
    cp report_name.html "$DOCS_DIR/"
    echo "  $DOCS_DIR/report_name.html"
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
echo "Report: report_name.html"
echo ""
echo "To explore results interactively:"
echo "  duckdb $DB_FILE"
