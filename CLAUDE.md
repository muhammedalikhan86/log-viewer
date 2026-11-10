# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project status

A log viewer that shows application logs per application, read from the existing
`ShawCentral.Trace.AuditTrail` table. Planned stack: Angular with Angular Material for the front end,
and a .NET Web API back end. **No code exists yet.** No phases have started — run `/idea-triage`
to write the PRD, Architecture and PMBook before any code. Once they exist, see `docs/handoff.md`
for the current build state and `docs/project-management.md` for the backlog.

## Starting the stack

No entrypoint exists yet, so there are no verified commands. Use the `run-app` skill
(`.claude/skills/run-app/SKILL.md`), which works the entrypoint out from the manifests. Once the
projects exist, record the real commands here, read from `package.json` and the `.csproj` /
`launchSettings.json`.

## Build / test commands

None yet — unverifiable until the projects are created. This is a two-toolchain repo (npm + dotnet):
any quality claim must cover **both** halves. A green run on one says nothing about the other.

Dependency audit note: `dotnet list package --vulnerable` reports findings but exits 0. Read its
output; don't gate on its exit code.

## Data source

- Table: `ShawCentral.Trace.AuditTrail`. Columns: `Timestamp` (datetime2), `ApplicationName`
  (varchar 50), `Action` (varchar 10), `TargetId` (uniqueidentifier), `Details` (varchar max),
  `Important` (bit), `Records` (int), `UserId` (nvarchar 100), `Server` (nvarchar 100).
- Indexed on `Timestamp` (clustered) and on `ApplicationName`. Filter by those.
- The same `Trace` schema also has `Trace.Exception` and `Trace.Information`.
- Access is through the read-only `DatabaseReader` SQL login on `idb_ag.shawstock.com.au,4433`.
  The app never writes. Don't commit the password, and don't commit a copy of the schema —
  query the server when you need it (`sys.columns` on `Trace.AuditTrail`).
- Data access in .NET uses the in-house `Shaw.DataAccess` package, not EF Core.

## Architecture

The plan is an Angular Material SPA calling a .NET Web API, which reads the table with read-only
queries. The full component breakdown, technology decisions and reasons will live in
`docs/architecture.md` and `docs/adr/`. Read those before a structural or technology change, and
add or amend an ADR when you make one.

Governed docs (`docs/prd.md`, `docs/architecture.md`, `docs/project-management.md`,
`docs/adr/`, `docs/handoff.md`) are specs the code must satisfy, not side artifacts —
keep them in sync with any structural change in the same session, not as a follow-up.

Diagrams are fenced `mermaid` blocks inside those docs. There is no `docs/diagrams/` folder and no
render script.
