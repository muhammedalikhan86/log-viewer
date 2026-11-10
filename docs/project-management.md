# Project Management: Log Viewer

> Status: ACTIVE
> Tranche: v1
> Version: v2
> Last updated: 2026-11-10
> PRD: docs/prd.md (built against v9)
> Architecture: docs/architecture.md (built against v6)

## Phases & Milestones

| Phase | Goal | Status |
|-------|------|--------|
| Phase 1 | Foundations: API and SPA skeletons, sign-in and group check, local databases, quality gates | Planned |
| Phase 2 | See the logs: one stream from the three tables, app picker, time range, results list with levels, shareable URL | Planned |
| Phase 3 | Investigate: filters, text search with highlighting, filter panel with counts, volume chart, entry detail | Planned |
| Phase 4 | Watch: live mode and the app summary | Planned |
| Phase 5 | Saved views: save, reopen, share | Planned |
| Phase 6 | Deploy: firm IIS standard on `sic2iws1`, first labelled release | Planned |

## Feature Backlog

| ID | Feature | Phase | Priority | Status | Acceptance Criteria |
|----|---------|-------|----------|--------|---------------------|
| F-001 | Solution and API skeleton | 1 | Must | Planned | `LogViewer.slnx` with a `net10.0` SDK-style Web API (`LogViewer.Api`) and a test project; folder-per-layer layout as `WebApis\PersonalContactUpdatePIS`; routes at the application root; `Shaw.*` v2.x as `PackageReference` from the internal feed; no `Shaw.Configuration`; Scalar/OpenAPI in Development only; `dotnet build` and `dotnet test` pass (ADR-001) |
| F-002 | SPA skeleton | 1 | Must | Planned | Angular app with Angular Material and a Material theme; `environment.ts` / `environment.prod.ts` (`apiBaseUrl: '/api/logviewer'`) swapped by `fileReplacements`; `ng serve` proxies to the API's localhost port; production build uses `--base-href /LogViewer/`; lint and unit tests pass (ADR-001) |
| F-003 | Sign-in and access check | 1 | Must | Planned | Negotiate auth on every endpoint; one policy allowing `Development Team - Sydney` or `IT Team` (names in configuration) via `Shaw.ActiveDirectory`, cached per user; a non-member gets 403 and the SPA shows a clear "no access" page; tests cover member, non-member and anonymous (ADR-002, FR-014) |
| F-004 | Configuration endpoint | 1 | Must | Planned | `GET /configuration` returns `webAPIVersion` and `loginUser.networkUsername` only; a test asserts no connection string or setting is ever returned (ADR-001) |
| F-005 | Connections and production-settings guard | 1 | Must | Planned | Connection keys `ShawCentral` and `LogViewer`; Development: `ShawCentral` via `DatabaseReader` with password in user secrets, `LogViewer` on LocalDB; `appsettings.Production.json` uses Integrated Security only; `ProductionSettingsTests` fails if any production string contains `User ID` or `Password` (ADR-007) |
| F-006 | Saved-views database and DbUp | 1 | Must | Planned | Embedded numbered SQL scripts create the `SavedView` table; DbUp applies them at start-up; start-up stops with a named error if the database is unreachable; works against LocalDB from a clean machine (ADR-005) |
| F-007 | Log reader: one stream | 2 | Must | Planned | Read-only parameterised SELECTs over `Trace.AuditTrail`, `Trace.Exception`, `Trace.Information` through `Shaw.DataAccess`; maps to the unified entry with level (Error / Important / Info / Audit) per architecture §4; every query bounded by time; newest first with cursor paging, page size 50; column names explicit; tests for the mapping and the cursor (ADR-003, FR-001, FR-002) |
| F-008 | Entries endpoint | 2 | Must | Planned | `GET /entries` accepts applications, levels, time from/to, cursor; validates input; returns 50 entries plus next cursor; a filtered page returns in under 2 s on a 15-minute window against the live server (NFR-001) |
| F-009 | Application list | 2 | Must | Planned | `GET /apps` returns every application name seen in the three tables; SPA multi-select picker (Material) with type-to-filter |
| F-010 | Results list with levels | 2 | Must | Planned | CDK virtual-scroll list: timestamp, level marker with colour, application, server, message (one line); loads the next 50 on scroll; empty, loading and error states (NFR-007) (FR-001, FR-002) |
| F-011 | Time range | 2 | Must | Planned | Presets 15 min, 1 h, 4 h, 24 h, 7 d, 30 d and exact from/to with Material datepicker; default last 15 minutes (FR-003) |
| F-012 | View state in the URL | 2 | Must | Planned | Every filter, search, range and setting is in the query string; opening a copied URL shows the same view; back/forward work (FR-011) |
| F-013 | Filters: level, server, action, user | 3 | Must | Planned | Filter by any mix of level, server, action and user; blanks handled ("no user"); combined with app and time filters on the server side (FR-002, FR-004) |
| F-014 | Text search with highlighting | 3 | Must | Planned | One search box over message text (and Method for errors/info); matches highlighted in the list and detail; with no app picked, range capped at the user-adjustable limit (default 7 days) with a warning when raised; the cap is kept in the URL (FR-005, FR-015, NFR-002) |
| F-015 | Filter panel with counts | 3 | Must | Planned | `GET /facets` returns counts per application, level and server for the current filter; left panel lists them; clicking one filters; counts refresh with the results (FR-007) |
| F-016 | Volume chart | 3 | Must | Planned | `GET /histogram` returns bucketed counts stacked by application, bucket size from the range; ECharts via `ngx-echarts`; dragging across the chart sets the time range (ADR-006, FR-006) |
| F-017 | Expand and entry detail | 3 | Must | Planned | Toggle between one line and full text per entry; opening an entry shows every field in a Material side panel or dialog, with a copy-to-clipboard action (FR-008) |
| F-018 | Live mode | 4 | Must | Planned | Material slide toggle; every 30 s requests entries newer than the newest held and adds them at the top; chart's last bucket refreshes; pauses when the tab is hidden; interval in configuration; new entries visible within 30 s (ADR-004, FR-009) |
| F-019 | Application summary | 4 | Should | Planned | Per application: last entry time and error count over the last 24 hours; an app silent for longer than a threshold is marked; clicking an app filters to it (FR-010) |
| F-020 | Saved views: save and reopen | 5 | Must | Planned | Save the current view under a name; list, open, rename and delete own views; owner taken from the signed-in identity, never the request (FR-012, NFR-006) |
| F-021 | Saved views: share | 5 | Must | Planned | Owner can share or unshare a view; shared views appear to every permitted user, read-only for non-owners; a non-owner cannot change or delete it (tests cover this) (FR-013) |
| F-022 | Deploy script | 6 | Must | Planned | `deploy/deploy.ps1` per the firm standard (DEP-1, DEP-3, DEP-4, DEP-7): PowerShell 5.1, `-Component api|web`, tests then publish/build, prompts to stop and start the `LogViewer` pool by hand, `robocopy /MIR` with exit-code check, `-PrepareOnly`; smoke-tests `GET /configuration`; never touches IIS itself |
| F-023 | Server setup and first release | 6 | Must | Planned | Administrator setup listed for DEP-8 (pool `LogViewer` as the firm gMSA, application `/api/logviewer`, Windows auth on, anonymous off); `LogViewer` database created empty; first release labelled per DEP-10 and recorded in `docs/releases.md`; `https://intranet.shawandpartners.com.au/LogViewer/` loads and shows logs |
| F-024 | Full-text index request | Later | Could | Planned | A written request to the IT Team for a full-text index on `Details` in the three `Trace` tables, with the search-speed evidence from F-014; if granted, search switches to it and the range cap default is revisited (risk A3) |

## Dependencies

| Item | Depends On | Blocks | Notes |
|------|-----------|--------|-------|
| F-003 | F-001 | F-008 onward | Every endpoint sits behind the access check |
| F-005 | F-001 | F-006, F-007 | Connection keys and settings guard |
| F-006 | F-005 | F-020 | Saved views need the table |
| F-007 | F-005 | F-008, F-013–F-016, F-018, F-019 | The reader underpins every log feature |
| F-010 | F-002, F-008 | F-013–F-018 | |
| F-012 | F-010, F-011 | F-020 | Saved views store the same state as the URL |
| F-014 | F-007 | F-024 | Evidence for the index request |
| F-022 | F-001, F-002 | F-023 | |
| F-023 | F-022, PM-002, PM-003 | — | Needs the administrator and the empty database |

## Out of Scope (confirmed in PRD)

- Changing, deleting or annotating log entries.
- Changing how applications write their logs.
- Per-application access limits.
- Alerting or notifications.
- Long-term reporting or trend dashboards.
- Keeping a copy of the logs, or managing how long they are kept (IT Team).

## Open Items

| ID | Item | Owner | Due |
|----|------|-------|-----|
| PM-001 | Ask the IT Team for a full-text index on the `Trace` tables (F-024) | Muhammed Ali Khan | After Phase 3 |
| PM-002 | Server administrator creates the `LogViewer` app pool (firm gMSA) and the `/api/logviewer` IIS application (DEP-8) | Muhammed Ali Khan | Before Phase 6 release |
| PM-003 | Create the empty `LogViewer` database on `idb_ag.shawstock.com.au,4433` | Muhammed Ali Khan | Before Phase 6 release |

## Version History

| Version | Date | Change | Triggered By | Approved By |
|---------|------|--------|---------------|-------------|
| v1 | 2026-11-10 | Initial draft | — | — |
| v2 | 2026-11-10 | PMBook approved | Gate approval | Muhammed Ali Khan |
