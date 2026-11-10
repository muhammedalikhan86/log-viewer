# ADR-006: Draw the volume chart with ECharts via ngx-echarts

> Status: ACCEPTED
> Date: 2026-11-10
> Architecture: docs/architecture.md (v6)

## Context

The volume chart (US-6) is a stacked bar or area over time, coloured by application, refreshed in
live mode. Angular Material has no chart component. In the estate, `Websites\PhoenixV3` (Angular 20)
uses `echarts` + `ngx-echarts`; `Websites\ClientEngagementSystem` uses `chart.js` + `ng2-charts`.

## Decision

Use ECharts through `ngx-echarts` for the volume chart.

## Alternatives Considered

| Option | Why not chosen |
|--------|-----------------|
| Chart.js via ng2-charts | Also used in the estate; weaker time-axis zoom and brush selection, which we want for "drag across the chart to set the time range" |
| Hand-drawn SVG | More code to own for axes, tooltips and resizing |

## Consequences

- Matches the newest Angular site in the estate.
- Brush/zoom lets a user drag across the chart to narrow the time range.
- Adds one charting dependency to the SPA.

## Related

- Architecture section: §3 SPA, FR-006
- Supersedes: none
