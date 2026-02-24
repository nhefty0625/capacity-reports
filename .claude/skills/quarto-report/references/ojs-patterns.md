# OJS Visualization Patterns

This reference documents the Observable JavaScript (OJS) patterns used across reports in
this repository. All visualizations use the `Plot` library (Observable Plot), `d3` for data
manipulation, and `Inputs` for interactive controls.

## Loading Data

Load CSV files produced by the SQL pipeline as `FileAttachment` objects:

```javascript
data = FileAttachment("data/agg_summary.csv").csv({typed: true})
```

The `{typed: true}` option auto-detects column types (numbers, dates, etc.).

## Color Palettes

Define color palettes as JavaScript objects for consistent styling across charts. Here is
an example pattern -- customize the categories and colors for your domain:

```javascript
// Example: status-based palette
statusColors = ({
  "Active": "#2563eb",
  "Warning": "#f77f00",
  "Critical": "#d62828",
  "Inactive": "#78716c",
  "Unknown": "#d4d4d4"
})

// Example: category-based palette
categoryColors = ({
  "Category A": "#2563eb",
  "Category B": "#d97706",
  "Category C": "#059669",
  "Category D": "#7c3aed",
  "Other": "#78716c"
})
```

Reuse palettes when reports touch the same domain concepts to maintain visual
consistency across the site.

## Chart Patterns

### Horizontal Bar Chart

Used for ranked comparisons (e.g., counts by category):

```javascript
Plot.plot({
  height: 350,
  marginLeft: 200,
  marginRight: 80,
  x: {label: "Count"},
  y: {label: null, domain: data.sort((a, b) => b.value - a.value).map(d => d.category)},
  color: {domain: Object.keys(colorMap), range: Object.values(colorMap)},
  marks: [
    Plot.barX(data, {
      y: "category",
      x: "value",
      fill: "category",
      sort: {y: "-x"}
    }),
    Plot.text(data, {
      y: "category",
      x: "value",
      text: d => d.value.toLocaleString(),
      dx: 5,
      textAnchor: "start"
    }),
    Plot.ruleX([0])
  ]
})
```

### Heatmap Matrix

Used for two-dimensional comparisons (e.g., category x dimension):

```javascript
{
  const maxCount = d3.max(matrixData, d => d.count) || 1;
  return Plot.plot({
    height: 350,
    width: 650,
    marginLeft: 200,
    marginBottom: 60,
    padding: 0.05,
    x: {label: "Column Dimension", domain: columnOrder},
    y: {label: null, domain: rowOrder},
    marks: [
      Plot.cell(matrixData, {
        x: "col",
        y: "row",
        fill: d => {
          if (d.count === 0) return "#f8f9fa";
          const t = Math.min(Math.log1p(d.count) / Math.log1p(maxCount), 1);
          return d3.interpolateYlOrRd(0.05 + t * 0.75);
        },
        title: d => `${d.row} / ${d.col}: ${d.count.toLocaleString()}`
      }),
      Plot.text(matrixData, {
        x: "col",
        y: "row",
        text: d => d.count > 0 ? d.count.toLocaleString() : "",
        fill: d => {
          const t = Math.min(Math.log1p(d.count) / Math.log1p(maxCount), 1);
          return t > 0.5 ? "white" : "black";
        },
        fontSize: 13,
        fontWeight: "bold"
      })
    ]
  });
}
```

Use `d3.interpolateBlues` for single-source heatmaps, `d3.interpolateYlOrRd` for
multi-source, and `d3.interpolateReds` for alert/risk contexts.

### Faceted Time Series

Used for daily trends broken out by category:

```javascript
dailyData = rawDaily
  .filter(d => d.category !== "Excluded")
  .map(d => ({...d, date: new Date(d.date_column)}))

Plot.plot({
  height: 400,
  width: 900,
  marginLeft: 60,
  x: {label: null, type: "time"},
  y: {label: "Count", grid: true},
  fy: {label: null, domain: categoryOrder},
  color: {domain: Object.keys(colorMap), range: Object.values(colorMap)},
  facet: {marginRight: 10},
  marks: [
    Plot.lineY(dailyData, {
      x: "date",
      y: "count",
      fy: "category",
      stroke: "category",
      strokeWidth: 1.5
    }),
    Plot.ruleY([0])
  ]
})
```

### Stacked Bar Chart

Used for composition breakdowns:

```javascript
Plot.plot({
  height: 350,
  marginLeft: 200,
  x: {label: "Count"},
  y: {label: null},
  color: {
    domain: ["Type A", "Type B"],
    range: ["#2563eb", "#93c5fd"],
    legend: true
  },
  marks: [
    Plot.barX(stackData, {
      y: "category",
      x: "count",
      fill: "type",
      sort: {y: "-x"}
    }),
    Plot.ruleX([0])
  ]
})
```

## Interactive Tables

### Basic Sortable Table

```javascript
Inputs.table(data, {
  columns: ["col_a", "col_b", "col_c"],
  header: {
    col_a: "Display Name A",
    col_b: "Display Name B",
    col_c: "Display Name C"
  },
  sort: "col_b",
  reverse: true,
  format: {
    col_c: d => d != null ? Math.round(d).toLocaleString() : "\u2014"
  }
})
```

### Filtered Table with Controls

Combine `Inputs.select`, `Inputs.text`, and reactive filtering:

```javascript
viewof categoryFilter = Inputs.select(
  ["All", ...new Set(data.map(d => d.category))],
  {label: "Category", value: "All"}
)

viewof searchBox = Inputs.text({
  label: "Search", placeholder: "Name...", width: 200
})

// Layout filters in a row
html`<div class="filter-row">
  <div>${viewof categoryFilter}</div>
  <div>${viewof searchBox}</div>
</div>`

// Reactive filtered data
filteredData = data.filter(d => {
  const matchCat = categoryFilter === "All" || d.category === categoryFilter;
  const matchSearch = !searchBox ||
    d.name?.toLowerCase().includes(searchBox.toLowerCase());
  return matchCat && matchSearch;
})

md`**Showing ${filteredData.length} of ${data.length} rows**`

Inputs.table(filteredData, {
  columns: [...],
  header: {...},
  sort: "count",
  reverse: true,
  rows: 25
})
```

## Executive Summary Pattern

Derive key metrics from loaded data and render as a markdown table:

```javascript
totalItems = d3.sum(summary, d => d.total)
linkedItems = d3.sum(summary.filter(d => d.category !== "Unlinked"), d => d.total)
linkedPct = (100 * linkedItems / totalItems).toFixed(1)

dates = daily.map(d => new Date(d.date)).filter(d => !isNaN(d))
startDate = d3.min(dates).toLocaleDateString("en-US", {year: "numeric", month: "short", day: "numeric"})
endDate = d3.max(dates).toLocaleDateString("en-US", {year: "numeric", month: "short", day: "numeric"})

md`**Data period: ${startDate} -- ${endDate}**

| Metric | Value |
|--------|-------|
| **Total items** | ${totalItems.toLocaleString()} |
| **Linked items** | ${linkedItems.toLocaleString()} (${linkedPct}%) |`
```

## Tabset Panels

Use Quarto's `panel-tabset` for multi-view comparisons:

```markdown
::: {.panel-tabset}

### Tab One

\`\`\`{ojs}
// visualization code
\`\`\`

### Tab Two

\`\`\`{ojs}
// visualization code
\`\`\`

:::
```

## Responsive CSS

The standard responsive CSS for desktop/tablet/mobile layouts with a sticky left-side
table of contents is included in `assets/report_template.qmd`. Copy it from the template
when creating new reports. The CSS handles three breakpoints:

- **Desktop (1200px+)**: Grid layout with sticky 250px sidebar
- **Tablet (768-1199px)**: Collapsed sidebar as horizontal nav
- **Mobile (<768px)**: Hidden sidebar

The template also includes `.filter-row` CSS for laying out filter controls in a
horizontal row above interactive tables.
