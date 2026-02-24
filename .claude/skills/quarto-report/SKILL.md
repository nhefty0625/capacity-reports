---
name: quarto-report
description: >
  This skill should be used when the user asks to "create a new report", "add an analysis",
  "scaffold a report", "start a new analysis project", "fetch data from Snowflake",
  "query Snowflake", "add a report to the site", "create a Quarto report",
  "update a report", or is working on any analysis project in this repository. Provides
  conventions, templates, and site integration steps that complement the general-purpose
  duckdb skill.
---

# Quarto Report Conventions

## Purpose

This skill provides the conventions, templates, and integration steps for building
Snowflake-to-Quarto analysis reports. It complements the general-purpose `duckdb` skill by
encoding the patterns that all reports in this repo follow. Use this skill alongside the
`duckdb` skill when creating or modifying analysis projects.

## Standard Project Structure

Every analysis project follows this layout:

```
project-name/
  fetch_data.sh              # Pulls data from Snowflake into data/
  run_analysis.sh            # Runs DuckDB pipeline + renders report
  sql/
    task_01_load_and_standardize.sql
    task_02_*.sql
    ...
  data/
    *.csv                    # Source data (from fetch) and aggregations (from SQL)
  report_name.qmd            # Quarto report with OJS visualizations
  analysis.duckdb            # DuckDB database (created by run_analysis.sh)
```

## Creating a New Report

### 1. Scaffold the Project

Create the directory and subdirectories. Use the templates in `assets/` as starting points:

- **`assets/fetch_data_template.sh`** -- Template for Snowflake data fetching
- **`assets/run_analysis_template.sh`** -- Template for pipeline orchestration
- **`assets/report_template.qmd`** -- Template for Quarto report with OJS and responsive CSS

Copy and adapt these templates. Make both shell scripts executable with `chmod +x`.

### 2. Fetch Data from Snowflake

Use the `snow` CLI to fetch data:

- **Default connection**: `snow sql -q 'SELECT ...' --format CSV > data/file.csv`
- **Named connection**: `snow sql -c connection_name -q 'SELECT ...' --format CSV > data/file.csv`

Customize the connection name and queries for your Snowflake environment. Edit
`fetch_data.sh` with the specific tables and queries your analysis needs.

### 3. Write SQL Pipeline

Follow the numbered task file convention. Each file runs sequentially via `duckdb analysis.duckdb < sql/task_NN.sql`.

**Task 01 -- Load and Standardize (always first):**
- Read CSVs with `read_csv('data/file.csv', AUTO_DETECT=TRUE, HEADER=TRUE)`
- Rename columns to `snake_case` using `AS` aliases
- End with row count validation

**Subsequent tasks -- Transform and aggregate:**
- Include validation queries after joins (row counts, join rates, null checks)
- Export final aggregation CSVs with `COPY table TO 'data/agg_*.csv' (HEADER, DELIMITER ',')`
- Name aggregation files with `agg_` prefix for clarity

### 4. Write the Quarto Report

Reports use OJS (Observable JavaScript) for interactive visualizations. Load CSV data as
`FileAttachment` objects, then use `Plot`, `Inputs.table`, and `d3` for charts and tables.

Consult **`references/ojs-patterns.md`** for visualization patterns:
bar charts, heatmap matrices, faceted time series, interactive filtered tables, tabset panels,
and the standard responsive CSS.

**Key Quarto frontmatter settings** (see `assets/report_template.qmd` for the full template):

- `embed-resources: true` -- Self-contained HTML for email sharing
- `page-layout: full` with `body-width: 1800px` -- Wide layout for data-heavy reports
- `toc: true` with `toc-location: left` -- Sticky left sidebar navigation
- `theme: cosmo` -- Standard theme across all reports
- `execute: echo: false` -- Hide code cells in rendered output

### 5. Integrate into the Site

After the report renders, integrate it into the Quarto site and deploy. Consult
**`references/site-integration.md`** for the complete checklist covering `_quarto.yml`
configuration, `docs/` directory setup, and the deployment workflow.

## Conventions

### Shell Scripts

- Start with `set -e` for fail-fast behavior
- Check required data files exist before running; print clear error messages if missing
- Remove existing `analysis.duckdb` before running to ensure a clean state
- Print progress with `[N/M]` step counters
- After completion, show how to explore interactively: `duckdb analysis.duckdb`
- Copy rendered HTML and data CSVs to `docs/project-name/` for GitHub Pages

### SQL Files

- Numbered `task_NN_descriptive_name.sql` format
- First task always loads and standardizes CSVs
- Include validation after every significant transformation
- Use `CREATE OR REPLACE TABLE` for idempotency
- Export aggregation CSVs with `agg_` prefix
- Cross-project dependencies: reference upstream data with `../other-project/data/file.csv`

### Quarto Reports

- Include a **Methodology** section at the end documenting data sources, join strategy,
  definitions, and limitations
- Provide CSV download links: `[Dataset (CSV)](data/agg_file.csv)`
- Use the `panel-tabset` class for multi-view comparisons
- Include an Executive Summary at the top with key metrics

### Cross-Project Dependencies

Some reports may join data from other projects. When depending on upstream data:

- Validate upstream files exist in `run_analysis.sh` before proceeding
- Print which upstream pipelines need to run if files are missing
- Reference upstream CSVs with relative paths: `../project-name/data/file.csv`

## Additional Resources

### Reference Files

- **`references/ojs-patterns.md`** -- OJS visualization patterns: charts, tables, filters, responsive CSS
- **`references/site-integration.md`** -- Adding to `_quarto.yml`, `docs/` setup, GitHub Pages deployment

### Asset Files (Templates)

- **`assets/fetch_data_template.sh`** -- Starting template for `fetch_data.sh`
- **`assets/run_analysis_template.sh`** -- Starting template for `run_analysis.sh`
- **`assets/report_template.qmd`** -- Starting template for Quarto report with OJS
