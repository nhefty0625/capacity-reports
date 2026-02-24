# Claude Reporting Template

A template for building Snowflake/DuckDB/Quarto report sites with Claude Code. Clone this repo and use the built-in slash commands to scaffold, render, and publish analysis reports.

## Prerequisites

- [Quarto](https://quarto.org/docs/get-started/) (1.4+)
- [DuckDB](https://duckdb.org/docs/installation/) CLI
- [Snowflake CLI](https://docs.snowflake.com/en/developer-guide/snowflake-cli/index) (`snow`) -- for fetching data
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) -- for the slash commands

## Quick Start

1. **Clone this template:**
   ```bash
   git clone <this-repo-url> my-reports
   cd my-reports
   ```

2. **Open in Claude Code:**
   ```bash
   claude
   ```

3. **Create your first project:**
   ```
   /new_project "Sales Analysis" Analyze quarterly sales by region
   ```

4. **Edit `fetch_data.sh`** with your Snowflake queries, then run it:
   ```bash
   cd sales-analysis
   ./fetch_data.sh
   ```

5. **Render and preview:**
   ```
   /render sales-analysis
   /preview
   ```

6. **Publish to GitHub Pages:**
   ```
   /publish
   ```

## Commands

| Command | Description |
|---------|-------------|
| `/new_project <title> <description>` | Scaffold a new analysis project with data pipeline and report |
| `/new_report <title> <description>` | Add a new report to an existing project |
| `/render [project-name]` | Render a report or the full site |
| `/preview [project-name]` | Start a live preview server |
| `/publish` | Commit and push to deploy via GitHub Pages |

## Project Structure

Each analysis project follows this layout:

```
project-name/
  fetch_data.sh              # Pulls data from Snowflake
  run_analysis.sh            # Runs DuckDB pipeline + renders report
  sql/
    task_01_load_and_standardize.sql
    task_02_*.sql
  data/
    *.csv                    # Source and aggregated data
  report-name.qmd            # Quarto report with OJS visualizations
```

The root of the repo is a Quarto website:

```
_quarto.yml                  # Site config, navbar, resources
index.qmd                   # Landing page with report links
docs/                        # Rendered output (deployed to GitHub Pages)
```

## How It Works

1. **Fetch**: `fetch_data.sh` uses the Snowflake CLI (`snow`) to pull data into `data/` as CSV files
2. **Transform**: `run_analysis.sh` runs numbered SQL task files through DuckDB to clean, join, and aggregate data
3. **Visualize**: Quarto reports use OJS (Observable JavaScript) for interactive charts and tables, loading data via `FileAttachment`
4. **Deploy**: Pushing to `main` triggers a GitHub Actions workflow that deploys the `docs/` directory to GitHub Pages

## Customization

### Site Title

Edit `_quarto.yml` and change `website.title`:

```yaml
website:
  title: "My Team's Reports"
```

### Color Palettes

Define domain-specific color palettes in your `.qmd` reports. See `.claude/skills/quarto-report/references/ojs-patterns.md` for patterns.

### Snowflake Connections

The default `fetch_data.sh` template uses `snow sql -q '...'`. For named connections, use `snow sql -c connection_name -q '...'`. Configure connections in `~/.snowflake/config.toml`.

## Deployment

This template uses GitHub Pages with GitHub Actions:

1. Enable GitHub Pages in your repo: Settings > Pages > Source: GitHub Actions
2. The workflow in `.github/workflows/pages.yml` deploys `docs/` on every push to `main`
3. Use `/publish` to commit and push in one step

## Skills

This template includes two Claude Code skills:

- **duckdb** -- SQL-first data analysis patterns, DuckDB conventions, validation checklists
- **quarto-report** -- Report scaffolding, OJS visualization patterns, site integration steps

These activate automatically when you work on analysis tasks in Claude Code.
