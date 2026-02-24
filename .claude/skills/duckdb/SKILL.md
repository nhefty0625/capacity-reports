---
name: duckdb
description: Local data analysis using DuckDB for CSV, TSV, Parquet, and JSON files. SQL-first approach for transformations, joins, aggregations, and data preparation. Includes patterns for Sankey diagrams, fuzzy matching, and multi-step data pipelines with numbered task files.
---

# DuckDB Data Analysis Skill

## Purpose
This skill is for local data analysis tasks involving CSV, TSV, Parquet, and JSON files. Use DuckDB as the primary tool for data transformations, analysis, and preparation - especially for reshaping data for visualization (like Sankey diagrams), aggregating data, and matching loosely related datasets.

## When to Use This Skill
- Analyzing or transforming CSV, TSV, Parquet, or JSON files
- Preparing data for visualization tools (especially Mermaid diagrams)
- Performing joins, aggregations, or data validation
- Working with datasets locally in `./data/` directory
- Tasks requiring SQL-based data manipulation

## Core Principles

### 1. SQL-First Approach
- Use SQL for all transformations, joins, aggregations, and validation
- Only use Python when SQL is impractical (complex string manipulation, advanced reshaping, API calls)
- Save all SQL transformations to numbered files reflecting execution order

### 2. File Naming Conventions
**SQL files:**
```
task_01_clean_customer_data.sql
task_02_join_orders_customers.sql
task_03_aggregate_by_region.sql
```

**Python files:**
```
task_04_fuzzy_matching.py
task_05_sankey_transform.py
```

### 3. Column Naming Standard
**Always transform column names to lowercase snake_case:**
- `EndpointID` → `endpoint_id`
- `Customer Name` → `customer_name`
- `Total_Sales` → `total_sales`

Apply this transformation early in your pipeline (typically task-01).

### 4. Data Output Formats
- **Intermediate artifacts**: Save as CSV files or tables within a DuckDB file
- **Final data outputs**: CSV or populated DuckDB database file
- **Analysis reports**: Markdown format with results and insights

## DuckDB SQL Patterns

### Basic Workflow Structure
```sql
-- task_01_standardize_columns.sql
CREATE TABLE cleaned_data AS
SELECT
    lower(replace(trim("Customer Name"), ' ', '_')) as customer_name,
    "Order ID"::INTEGER as order_id,
    "Total Sales"::DECIMAL(10,2) as total_sales
FROM read_csv('data/raw_data.csv', AUTO_DETECT=TRUE);

-- Export to CSV
COPY cleaned_data TO 'data/cleaned_data.csv' (HEADER, DELIMITER ',');
```

### Reading Files
```sql
-- CSV with auto-detection
FROM read_csv('data/file.csv', AUTO_DETECT=TRUE)

-- Parquet
FROM read_parquet('data/file.parquet')

-- JSON
INSTALL json;
LOAD json;
FROM read_json('data/file.json')

-- TSV
FROM read_csv('data/file.tsv', delimiter='\t', AUTO_DETECT=TRUE)
```

### Data Validation
```sql
-- task_03_validate_join.sql
-- Check row counts before and after join
SELECT 'source_table' as table_name, COUNT(*) as row_count FROM source_table
UNION ALL
SELECT 'joined_table', COUNT(*) FROM joined_table;

-- Check for nulls introduced by join
SELECT
    COUNT(*) as total_rows,
    COUNT(*) FILTER (WHERE key_column IS NULL) as null_keys,
    COUNT(*) FILTER (WHERE value_column IS NULL) as null_values
FROM joined_table;
```

### Common Transformations

**Aggregations:**
```sql
-- task_02_aggregate_sales.sql
CREATE TABLE sales_by_region AS
SELECT
    region,
    COUNT(*) as order_count,
    SUM(total_sales) as total_revenue,
    AVG(total_sales) as avg_order_value
FROM orders
GROUP BY region
ORDER BY total_revenue DESC;
```

**Reshaping for Sankey Diagrams:**
```sql
-- task_03_sankey_prep.sql
-- Create source-target-value format for Sankey
CREATE TABLE sankey_data AS
SELECT
    source_category as source,
    target_category as target,
    SUM(value) as value
FROM transitions
GROUP BY source_category, target_category
HAVING SUM(value) > 0;

COPY sankey_data TO 'data/sankey_data.csv';
```

**Fuzzy Matching Setup:**
```sql
-- task_02_prep_for_matching.sql
-- Prepare data with normalized strings for matching
CREATE TABLE normalized_companies AS
SELECT
    company_id,
    company_name,
    LOWER(TRIM(REGEXP_REPLACE(company_name, '[^a-zA-Z0-9]', '', 'g'))) as normalized_name
FROM companies;
```

## Python Integration

### When to Use Python
- Fuzzy/similarity matching (not available in SQL)
- Complex nested transformations
- Advanced string manipulation beyond SQL capabilities
- Generating specific visualization formats

### Python with DuckDB API
```python
# task_04_fuzzy_matching.py
import duckdb
from rapidfuzz import fuzz
import polars as pl

# Connect to DuckDB (or use in-memory)
con = duckdb.connect('data/analysis.duckdb')

# Read data using DuckDB
df1 = con.execute("SELECT * FROM normalized_companies").pl()
df2 = con.execute("SELECT * FROM vendors").pl()

# Perform fuzzy matching
matches = []
for company in df1.iter_rows(named=True):
    for vendor in df2.iter_rows(named=True):
        score = fuzz.ratio(company['normalized_name'], vendor['vendor_name'])
        if score > 85:
            matches.append({
                'company_id': company['company_id'],
                'vendor_id': vendor['vendor_id'],
                'match_score': score
            })

# Write back to DuckDB
matches_df = pl.DataFrame(matches)
con.execute("CREATE TABLE matched_records AS SELECT * FROM matches_df")

# Export if needed
con.execute("COPY matched_records TO 'data/matched_records.csv'")
con.close()
```

### Polars Integration
```python
# task_05_complex_reshape.py
import polars as pl
import duckdb

# Read with Polars
df = pl.read_csv('data/source.csv')

# Complex transformation
result = (
    df
    .with_columns([
        pl.col('date').str.strptime(pl.Date, '%Y-%m-%d'),
        pl.col('amount').cast(pl.Float64)
    ])
    .pivot(values='amount', index='category', columns='month')
)

# Write back through DuckDB for consistency
con = duckdb.connect('data/analysis.duckdb')
con.execute("CREATE TABLE pivoted_data AS SELECT * FROM result")
con.execute("COPY pivoted_data TO 'data/pivoted_data.csv'")
con.close()
```

## Workflow Examples

### Example 1: CSV Analysis Pipeline
```bash
# File structure:
# data/raw_sales.csv
# task_01_clean_columns.sql
# task_02_aggregate_by_region.sql
# task_03_validate_results.sql
# results.md
```

### Example 2: Multi-File Join with DuckDB Database
```bash
# Create persistent database
duckdb data/analysis.duckdb

# Within DuckDB CLI or via SQL files:
# task_01_load_all_sources.sql
# task_02_join_datasets.sql
# task_03_final_aggregation.sql
```

### Example 3: Sankey Diagram Preparation
```bash
# task_01_standardize_columns.sql
# task_02_aggregate_flows.sql
# task_03_format_for_mermaid.py  # if complex formatting needed
# data/sankey_flow.csv (output)
```

## Documentation Guidelines

- **Don't document** standard SQL patterns (SELECT, JOIN, GROUP BY)
- **Do document** when using:
  - Window functions with complex partitioning
  - Recursive CTEs
  - QUALIFY clauses
  - Advanced DuckDB-specific functions
  - Non-obvious business logic

Example of when to add comments:
```sql
-- Using QUALIFY to get top 3 per group (DuckDB-specific alternative to ROW_NUMBER filtering)
SELECT
    category,
    product_name,
    revenue
FROM sales
QUALIFY ROW_NUMBER() OVER (PARTITION BY category ORDER BY revenue DESC) <= 3;
```

## Validation Checklist

After each significant transformation, check:
1. **Row counts**: Did we lose/gain unexpected rows?
2. **Null values**: Any unexpected NULLs after joins?
3. **Data types**: Are columns the expected type?
4. **Key uniqueness**: Are assumed-unique keys actually unique?

```sql
-- Quick validation query
SELECT
    'Row count' as check_type,
    COUNT(*)::VARCHAR as value
FROM result_table
UNION ALL
SELECT 'Null primary keys', COUNT(*)::VARCHAR
FROM result_table WHERE id IS NULL
UNION ALL
SELECT 'Duplicate keys', (COUNT(*) - COUNT(DISTINCT id))::VARCHAR
FROM result_table;
```

## Tips & Best Practices

1. **Use AUTO_DETECT**: Let DuckDB infer schemas for CSVs
2. **Persistent vs In-Memory**: Use file-based DuckDB (`analysis.duckdb`) for multi-step pipelines; in-memory for quick tasks
3. **Export frequently**: Save intermediate results as CSV for inspection
4. **Chain with pipes**: DuckDB supports `FROM previous_query` patterns
5. **Check execution plans**: Use `EXPLAIN` for complex queries if needed (rare)
6. **Extension management**: Only load extensions when needed (json, spatial)

## Error Handling

Common issues and solutions:

**"Table not found"**
- Ensure previous SQL files created the table
- Check if using file-based DB consistently

**"Column doesn't exist"**
- Remember to use double quotes for original mixed-case names
- Check if column renaming happened in earlier step

**"Type mismatch"**
- Explicitly cast with `::TYPE` syntax
- Use `TRY_CAST` to avoid errors and get NULL instead

## Output Expectations

**For analysis tasks:**
- `data/` directory with all CSV/Parquet files
- `task_NN_description.sql` files in execution order
- Optional `task_NN_description.py` files if needed
- `analysis.md` with findings, counts, and insights
- Optional `analysis.duckdb` if using persistent database

**Column names in all outputs:**
- Must be lowercase_snake_case
- No spaces, no special characters except underscore
- Descriptive and consistent across files

## Quick Reference

```bash
# DuckDB CLI commands
duckdb database.duckdb              # Open/create database
.read task_01_load.sql              # Execute SQL file
.tables                             # List tables
.schema table_name                  # Show table structure
.exit                               # Quit

# Common SQL patterns
DESCRIBE table_name;                # Show schema
SUMMARIZE table_name;               # Quick statistics
SHOW TABLES;                        # List all tables
```

---

**Remember**: Prioritize code clarity over performance. Write SQL that's easy to understand and maintain. Use meaningful task names that describe what each transformation does.
