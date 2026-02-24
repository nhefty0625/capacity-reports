---
allowed-tools: Bash, Read, Glob, Grep
description: Start a Quarto preview server
user-intent: preview
---

# /preview $ARGUMENTS

Start a Quarto preview server so the user can see their site in a browser.

## Steps

1. **Identify the target.** If `$ARGUMENTS` contains a project name, preview just that report. If empty, preview the whole site.

2. **Start the preview server as a background task.** Use the Bash tool with `run_in_background: true`:
   - For a single report: `quarto preview <project-name>/<report>.qmd`
   - For the whole site: `quarto preview`

3. **Report the preview URL.** Quarto typically serves at `http://localhost:PORT`. Tell the user:
   - The preview URL (usually `http://localhost:4200` or similar)
   - That the preview is running in the background
   - That changes to `.qmd` files will auto-reload
   - They can continue working while the preview runs
