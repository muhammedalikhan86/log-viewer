# ADR-004: Live mode polls for new entries every 30 seconds

> Status: ACCEPTED
> Date: 2026-11-10
> Architecture: docs/architecture.md (v6)

## Context

Live mode must show a new entry within 30 seconds of it being written. The app does not write the
logs and gets no event when a row is added, so something must look for new rows either way.
Expected users are few (two IT groups).

## Decision

The SPA polls `GET /api/entries?after=<newest timestamp>` every 30 seconds while live mode is on and
the tab is visible.

## Alternatives Considered

| Option | Why not chosen |
|--------|-----------------|
| SignalR push from the server | The server would still have to poll SQL; adds a persistent connection and more code for no faster result |
| SQL Server change tracking / Service Broker | Needs changes to `ShawCentral` by the IT Team |

## Consequences

- Simple and stateless; works through any proxy.
- Worst-case delay is about 30 s plus query time, at the 30 s target (PRD v9). The interval is a setting, so it can be shortened if users need it.
- Each open live tab makes one small time-bounded query every 30 s (risk A4).

## Related

- Architecture section: §4 Live mode, NFR-003
- Supersedes: none
