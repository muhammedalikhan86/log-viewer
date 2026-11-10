# ADR-003: Read the three Trace tables directly and show them as one stream

> Status: ACCEPTED
> Date: 2026-11-10
> Architecture: docs/architecture.md (v6)

## Context

Logs live in `ShawCentral.Trace.AuditTrail`, `Trace.Exception` and `Trace.Information`. They share
`Timestamp`, `ApplicationName`, `Details`, `UserId` and `Server`, and differ in the rest
(`Action`/`TargetId`/`Records`/`Important` vs `Method`/`FilePath`). All three are clustered on
`Timestamp` and indexed on `ApplicationName`. There is no full-text index. History is managed by
the IT Team outside this project, and the PRD rules out the viewer keeping its own copy.

## Decision

Query the three tables directly with read-only, parameterised SQL through `Shaw.DataAccess`,
combine the results into one entry shape with a derived level (Error, Important, Info, Audit), and
always bound every query by a time range.

## Alternatives Considered

| Option | Why not chosen |
|--------|-----------------|
| Copy logs into a search engine (e.g. Elasticsearch) | PRD non-goal: no copy of the logs; new infrastructure to run |
| Ask IT for a combined view in `ShawCentral` | Needs a change by another team; the union is easy to do in the reader |
| Query each table separately and show three tabs | PRD wants all kinds for one moment in one place |

## Consequences

- Always shows exactly what is in the table, with no sync lag.
- Load lands on a shared production database; mitigated by time bounds, page size limits and
  cursor paging (NFR-001–003).
- Text search is `LIKE`-based and limited in range by a user-adjustable cap (NFR-002, risk A3).
- Deployed, the reader connects with Integrated Security as the app pool's gMSA (ADR-007);
  development uses `DatabaseReader`.
- If the IT Team changes the table shapes, the reader breaks; queries name their columns
  explicitly so a change fails loudly.

## Related

- Architecture section: §3 Log reader, §4 Unified log entry
- Supersedes: none
