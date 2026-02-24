---
allowed-tools: Bash, Read, Glob, Grep
description: Commit and push to deploy via GitHub Pages
user-intent: publish
---

# /publish

Commit the current changes and push to trigger the GitHub Pages deployment.

## Steps

1. **Show current status.** Run `git status` and `git diff --stat` to show the user what has changed.

2. **Ask for confirmation.** Show the user:
   - Which files will be committed
   - Remind them that `.duckdb` files are excluded by `.gitignore`
   - Ask them to confirm before proceeding

3. **Stage files.** Stage source files and rendered output:
   ```
   git add -A
   ```
   The `.gitignore` already excludes `.duckdb` and `.duckdb.wal` files.

4. **Commit.** Create a descriptive commit message based on what changed (e.g., "Add sales-analysis report" or "Update customer-churn report data"). Use the commit message convention:
   ```
   git commit -m "descriptive message"
   ```

5. **Push.** Push to the remote:
   ```
   git push
   ```

6. **Report results.** Tell the user:
   - The commit was created and pushed
   - The GitHub Pages workflow will deploy automatically (triggered by changes to `docs/`)
   - Remind them to check their repo's Settings > Pages to ensure GitHub Pages is configured to use GitHub Actions as the source
