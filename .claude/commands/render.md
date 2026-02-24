---
allowed-tools: Bash, Read, Glob, Grep, Edit, Write
description: Render a Quarto report or the full site
user-intent: render
---

# /render $ARGUMENTS

Render a Quarto report. The user may provide a project name as an argument, or omit it.

## Steps

1. **Identify the target.** If `$ARGUMENTS` contains a project name, use that project. If empty, list the project directories (any directory containing a `.qmd` file and a `sql/` subdirectory) and ask the user which to render, or offer to render the entire site.

2. **Find the .qmd file.** Look in the project directory for `.qmd` files. If there is exactly one, use it. If there are multiple, ask the user which to render.

3. **Render from the repo root.** Run:
   ```
   quarto render <project-name>/<report>.qmd
   ```
   from the repository root directory (not from within the project directory). This ensures `output-dir: docs` in `_quarto.yml` is respected.

4. **Copy aggregation CSVs.** After rendering, copy any `data/agg_*.csv` files from the project to `docs/<project-name>/data/`:
   ```
   mkdir -p docs/<project-name>/data
   cp <project-name>/data/agg_*.csv docs/<project-name>/data/
   ```

5. **Report results.** Tell the user:
   - Whether the render succeeded or failed (include any error output)
   - Where the output HTML landed (in `docs/`)
   - How many data files were copied
   - Suggest running `/preview` to check the result, or `/publish` to deploy
