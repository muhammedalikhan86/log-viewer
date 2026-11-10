# ADR-005: Saved views live in an app-owned `LogViewer` database, migrated by DbUp

> Status: ACCEPTED
> Date: 2026-11-10
> Architecture: docs/architecture.md (v6)

## Context

Saved views must persist and be shareable between users (US-12, US-13). `ShawCentral` is read-only
to this app. The owner asked to use LocalDB for now and move to a new database at deployment.
`shaw-plugin-dashboard` does exactly this: each API owns a database, LocalDB in development; in
production the developer creates it empty before the first release and the API adds its own tables
on first start with DbUp. The firm gMSA already has access to new databases on the server.

## Decision

Store saved views in a `LogViewer` SQL Server database owned by this app, with its schema as
numbered SQL scripts embedded in the API and applied by DbUp at start-up — LocalDB in development,
`LogViewer` on `idb_ag.shawstock.com.au,4433` when deployed.

## Alternatives Considered

| Option | Why not chosen |
|--------|-----------------|
| New table in `ShawCentral` | Writes into a shared database owned by the IT Team |
| A `.sqlproj` deployed by hand (e.g. `FeeDisclosureDatabase`) | A separate manual deployment step; DbUp keeps the schema in step with the API release, as in `shaw-plugin-dashboard` |
| Browser local storage | Cannot share views between users |
| JSON file on the server | Lost on a `/MIR` release or server rebuild; needs Modify rights on the API folder |

## Consequences

- No request to the IT Team in development, and none at deployment beyond creating an empty database.
- In development, sharing only works between users of the same machine (risk A5).
- If the database is unreachable at start-up, the API stops with a named error instead of
  starting without saved views.
- The schema is versioned in this repo alongside the code that uses it.

## Related

- Architecture section: §3 Saved-view store, §4 Saved views
- ADR-007
- Supersedes: none
