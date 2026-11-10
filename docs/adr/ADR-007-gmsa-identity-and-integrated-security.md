# ADR-007: The API runs as the firm gMSA and connects with Integrated Security

> Status: ACCEPTED
> Date: 2026-11-10
> Architecture: docs/architecture.md (v6)

## Context

The deployed API reads `ShawCentral` and reads/writes its own `LogViewer` database. The
`DatabaseReader` SQL login is approved for analysis and design, not for a deployed app. Firm
practice, recorded in `shaw-plugin-dashboard` (`docs/deployment/README.md`,
`docs/adr/SHELL-ADR-022-intranet-iis-deployment.md`, `docs/adr/SHELL-ADR-025-initiative-shared-subject-database.md`):

- every API's app pool runs as the firm's existing gMSA, never `ApplicationPoolIdentity` (`DEP-8`);
- every production connection string is Windows Integrated Security as that gMSA, with no user
  name or password, shipped in `appsettings.Production.json`;
- the gMSA already has access to every database on the server, new ones included, so no grants are
  needed (administrator, 2026-10-12);
- a database login of its own for each API was rejected by the product owner: every Shaw
  application runs as the one gMSA by design.

## Decision

Run the `LogViewer` app pool as the firm gMSA and make every production connection — `ShawCentral`
and `LogViewer` — Windows Integrated Security as that account, set in a committed
`appsettings.Production.json` that holds no credentials.

## Alternatives Considered

| Option | Why not chosen |
|--------|-----------------|
| `DatabaseReader` SQL login in production | Approved for analysis and design only; puts a password in config |
| A dedicated SQL login for this app | Rejected firm-wide: every Shaw app runs as the one gMSA |
| `ApplicationPoolIdentity` | Forbidden by `DEP-8` |
| Production settings kept only on the server | Drifts out of sight of source control; with Integrated Security there is no secret to hide |

## Consequences

- No passwords in any deployed file. A `ProductionSettingsTests` test fails the build if a
  production connection string ever gains `User ID` or `Password`.
- Connection-string keys are the `Shaw.DataAccess` database names (`ShawCentral`, `LogViewer`) and
  stay the same in every environment; only the server/catalog and auth differ.
- Development: `ShawCentral` through `DatabaseReader`, password in .NET user secrets; `LogViewer` on
  LocalDB with Windows auth. Neither is deployed.
- The gMSA can reach more than this app needs; least privilege is enforced in code (SELECT only
  against `ShawCentral`; writes only to `LogViewer`).
- Changing a production connection string is a code change and a release.

## Related

- Architecture section: §2, §3 Log reader and Saved-view store, §9
- ADR-001, ADR-005
- Supersedes: none
