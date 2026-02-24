---
allowed-tools: Bash, Read, Glob, Grep, Edit, Write
description: Scaffold a new analysis project
user-intent: new_project
---

# /new_project $ARGUMENTS

Create a new analysis project. The user provides a title and description as arguments, e.g.:
`/new_project "Sales Analysis" Analyze quarterly sales data by region and product category`

The first quoted string (or first few words) is the title. Everything after is the description.

## Steps

### 1. Parse arguments

Extract the project title and description from `$ARGUMENTS`. Derive a kebab-case slug from the title (e.g., "Sales Analysis" becomes `sales-analysis`).

### 2. Create project directory structure

```
mkdir -p <slug>/sql <slug>/data
```

### 3. Create fetch_data.sh

Read the template from `.claude/skills/quarto-report/assets/fetch_data_template.sh`. Copy it to `<slug>/fetch_data.sh` and customize:
- Replace `PROJECT_TITLE` with the actual title
- Replace `DESCRIPTION_OF_WHAT_THIS_FETCHES` with the description
- Leave the Snowflake query placeholders -- the user will fill these in

Make it executable: `chmod +x <slug>/fetch_data.sh`

### 4. Create run_analysis.sh

Read the template from `.claude/skills/quarto-report/assets/run_analysis_template.sh`. Copy it to `<slug>/run_analysis.sh` and customize:
- Replace `PROJECT_TITLE` with the actual title
- Replace `DESCRIPTION_OF_WHAT_THIS_ANALYZES` with the description
- Replace `project-name` in the `DOCS_DIR` path with the actual slug
- Replace `report_name` with the kebab-case slug for the report filename

Make it executable: `chmod +x <slug>/run_analysis.sh`

### 5. Create the SQL pipeline and .qmd report

Use the duckdb skill to create an initial SQL pipeline structure and a Quarto report based on the project description. At minimum:
- Create `sql/task_01_load_and_standardize.sql` with placeholder SQL that loads from `data/` CSVs
- Create `<slug>.qmd` from the report template in `.claude/skills/quarto-report/assets/report_template.qmd`, customizing the title, subtitle, and file attachment paths

### 6. Update `_quarto.yml`

Read the current `_quarto.yml` and add:
- A new navbar entry under `website.navbar.left`:
  ```yaml
  - href: <slug>/<slug>.qmd
    text: <Title>
  ```
- A new resources glob under `project.resources`:
  ```yaml
  - "<slug>/data/*.csv"
  ```

### 7. Update `index.qmd`

Read the current `index.qmd`. If it still contains the placeholder text ("_No reports yet..."), remove that line. Add a link to the new report under the "## Reports" heading:
```
- [<Title>](<slug>/<slug>.qmd) -- <description>
```

### 8. Create docs directory

```
mkdir -p docs/<slug>/data
```

### 9. Summarize

Tell the user what was created:
- Project directory with `fetch_data.sh`, `run_analysis.sh`, `sql/`, `data/`
- Report `.qmd` file
- Site navigation updated in `_quarto.yml`
- Landing page updated in `index.qmd`

Suggest next steps:
1. Edit `fetch_data.sh` with your Snowflake queries
2. Run `./fetch_data.sh` to pull data
3. Refine the SQL pipeline in `sql/`
4. Run `/render <slug>` to build the report
