---
allowed-tools: Bash, Read, Glob, Grep, Edit, Write
description: Add a new report to an existing project
user-intent: new_report
---

# /new_report $ARGUMENTS

Add a new report to an existing analysis project. The user provides a title and description, e.g.:
`/new_report "Monthly Trends" Show monthly trends over time for the key metrics`

## Steps

### 1. Identify the target project

Check if the user is currently in a project subdirectory (look for `run_analysis.sh` or `sql/` in the current directory or parent). If not, list the available projects and ask the user which one to add the report to.

### 2. Read existing project state

- Read the existing SQL files in `sql/` to understand the current pipeline and numbering
- Read any existing `.qmd` files to understand the current report structure
- Read `run_analysis.sh` to understand the current pipeline steps
- Identify what data files exist in `data/`

### 3. Parse arguments

Extract the report title and description from `$ARGUMENTS`. Derive a kebab-case filename for the new `.qmd` file (e.g., "Monthly Trends" becomes `monthly-trends.qmd`).

### 4. Create additional SQL tasks

Use the duckdb skill to create any additional SQL task files needed for the new report. Continue the existing numbering sequence (e.g., if the last task is `task_03_*.sql`, start with `task_04_*.sql`).

### 5. Create the new .qmd report

Create the new report file from the template in `.claude/skills/quarto-report/assets/report_template.qmd`. Customize:
- Title and subtitle
- FileAttachment paths to match the data files this report will use
- Initial visualization structure based on the description

### 6. Update `_quarto.yml`

Read the current `_quarto.yml` and update the navbar entry for this project:

- **If the project currently has a single navbar entry** (simple `href`), convert it to a dropdown menu:
  ```yaml
  - text: Project Title
    menu:
      - href: project/existing-report.qmd
        text: Existing Report
      - href: project/new-report.qmd
        text: New Report
  ```

- **If the project already has a dropdown**, add the new report to the existing menu:
  ```yaml
      - href: project/new-report.qmd
        text: New Report Title
  ```

### 7. Update `run_analysis.sh`

Edit `run_analysis.sh` to:
- Add execution steps for any new SQL tasks
- Add a `quarto render` step for the new report
- Update the step counter (`[N/M]` format)
- Copy the new report's HTML to `docs/`

### 8. Summarize

Tell the user what was created:
- New `.qmd` report file
- Any new SQL task files
- Updated `_quarto.yml` navigation (dropdown if converted)
- Updated `run_analysis.sh`

Suggest next steps:
1. Add or adjust SQL tasks for the new report's data needs
2. Customize the `.qmd` visualizations
3. Run `/render <project>` to build both reports
