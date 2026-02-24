# Site Integration & Deployment

## Adding a New Report to the Site

After a report is created and rendering successfully, integrate it into the Quarto site
with these steps.

### 1. Update `_quarto.yml`

The root `_quarto.yml` controls the site navigation and resource bundling. Two sections
need updating.

#### Add to Navbar

Add the report to `website.navbar.left`:

```yaml
website:
  navbar:
    left:
      # ... existing entries ...
      - href: your-project/report_name.qmd
        text: Display Name
```

For reports with multiple pages or an RFC, use a dropdown menu:

```yaml
      - text: Display Name
        menu:
          - href: your-project/report_name.qmd
            text: Report
          - href: your-project/rfc.md
            text: RFC
```

#### Add to Resources

Add data CSVs to `project.resources` so Quarto bundles them for `FileAttachment` access:

```yaml
project:
  resources:
    # ... existing entries ...
    - "your-project/data/*.csv"
```

### 2. Set Up the `docs/` Directory

Create the output directory for GitHub Pages:

```bash
mkdir -p docs/your-project/data
```

### 3. Render from the Repo Root

Render using Quarto from the repository root (not from within the project directory):

```bash
quarto render your-project/report_name.qmd
```

This outputs to `docs/your-project/` per the `output-dir: docs` setting in `_quarto.yml`.

### 4. Copy Data Files

If the `run_analysis.sh` doesn't already handle this, manually copy aggregation CSVs
for download links:

```bash
cp your-project/data/agg_*.csv docs/your-project/data/
```

### 5. Update `run_analysis.sh`

Ensure the shell script copies output to `docs/` at the end:

```bash
DOCS_DIR="../docs/your-project"
mkdir -p "$DOCS_DIR/data"

# Copy rendered HTML
cp report_name.html "$DOCS_DIR/"

# Copy data CSVs for download links
for csv in data/agg_*.csv; do
    if [ -f "$csv" ]; then
        cp "$csv" "$DOCS_DIR/data/"
    fi
done
```

## Deployment Workflow

### How Deployment Works

The site deploys automatically via `.github/workflows/pages.yml`:

- **Trigger**: Any push to `main` that modifies files under `docs/`
- **Mechanism**: Uploads `docs/` as a GitHub Pages artifact
- **No server-side build**: HTML is pre-rendered locally and committed to the repo

### Standard Deploy Flow

```bash
# 1. Run the analysis pipeline (fetches data if needed)
cd your-project
./fetch_data.sh        # If data needs refreshing
./run_analysis.sh      # Runs SQL pipeline + renders + copies to docs/

# 2. Commit source AND rendered output
cd ..
git add your-project/ docs/your-project/
git commit -m "Add your-project analysis report"

# 3. Push to main -- pages deploy triggers automatically
git push
```

### Pre-render Hooks

For projects that need automated data preparation, add a pre-render hook in `_quarto.yml`:

```yaml
project:
  pre-render:
    - cd your-project && ./prepare_data.sh
```

This runs before `quarto render` when rendering the full site.

## Checklist

Before pushing a new report:

- [ ] `_quarto.yml` updated with navbar entry and resources glob
- [ ] `docs/your-project/` directory created with HTML and data CSVs
- [ ] `run_analysis.sh` copies output to `docs/` directory
- [ ] Report renders successfully from repo root: `quarto render your-project/report.qmd`
- [ ] CSV download links in the report work correctly
- [ ] Report appears in site navigation when previewing with `quarto preview`
