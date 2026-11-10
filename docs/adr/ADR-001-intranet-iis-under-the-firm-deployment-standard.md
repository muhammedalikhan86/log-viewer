# ADR-001: Deploy to the intranet IIS server under the firm's IIS Deployment Standard

> Status: ACCEPTED
> Date: 2026-11-10
> Architecture: docs/architecture.md (v6)

## Context

The viewer needs a browser UI (Angular with Angular Material, the Shaw UI standard) and a server
that reads SQL and checks AD groups. The firm has an IIS Deployment Standard (`DEP-1` … `DEP-10`)
for every Angular + .NET product on the production intranet server `sic2iws1`. The server
administrator's layout puts front ends under `\\sic2iws1\inetpub\wwwroot\<AppFolder>` and APIs under
`\\sic2iws1\WebAPI\<AppFolder>`, served at `/api`; the option of the API serving the front end was
rejected for that reason. `shaw-plugin-dashboard` applies this standard
(`docs/adr/SHELL-ADR-022-intranet-iis-deployment.md`, `docs/deployment/`), including its one
deviation: no central configuration, because the administrator called
`ShawCentral.dbo.Configuration` legacy.

## Decision

Deploy the Log Viewer to `sic2iws1` as two IIS applications on the intranet host — the Angular SPA as
static files at `/LogViewer/` and a .NET 10 Web API at `/api/logviewer` in its own `LogViewer` app
pool — following the firm standard as `shaw-plugin-dashboard` applies it.

| Placeholder | Value |
|---|---|
| `<AppFolder>` | `LogViewer` |
| `<api-slug>` | `logviewer` |
| `<AppPool>` | `LogViewer` |
| Web folder | `\\sic2iws1\inetpub\wwwroot\LogViewer` |
| API folder | `\\sic2iws1\WebAPI\LogViewer` |
| Front-end URL | `https://intranet.shawandpartners.com.au/LogViewer/` |
| API URL | `https://intranet.shawandpartners.com.au/api/logviewer` |

## Alternatives Considered

| Option | Why not chosen |
|--------|-----------------|
| One ASP.NET Core host serving both SPA and API | Rejected by the server administrator's layout (front ends under `wwwroot`, APIs under `WebAPI`) |
| Separate hosts with CORS (older Phoenix pattern) | Needs CORS-with-credentials; the standard puts both on one host instead |
| Central configuration via `SP_GETCONFIGURATION` (`DEP-5` as written) | Administrator advised the table is legacy (2026-10-12) |

## Consequences

- Same origin, so no CORS; the intranet host is already in the firm's Edge `AuthServerAllowlist`.
- API routes sit at the application root; IIS supplies `/api/logviewer`.
- The SPA reads its API address from Angular environment files (`DEP-6`) and is built with
  `--base-href /LogViewer/`.
- `deploy/deploy.ps1` follows the standard's templates: PowerShell 5.1, `robocopy /MIR`, prompts the
  deployer to stop and start the `LogViewer` pool by hand, never touches IIS itself (`DEP-1`), and is
  run by a person, not an agent (`DEP-3`).
- `GET /configuration` returns `webAPIVersion` and `loginUser.networkUsername` for the smoke test,
  never a configuration value.
- An administrator does the one-off server setup (`DEP-8`): the `LogViewer` pool ("No Managed
  Code", identity the firm gMSA) and the `/api/logviewer` application with Windows auth on and
  anonymous off.
- Releases are labelled and recorded per `DEP-10`.
- Locally, `ng serve` proxies to the API's localhost port, so the two halves start separately.

## Related

- Architecture section: §1 System Context, §2 High-Level Architecture, §3 Components
- ADR-007 (service identity and connections)
- Supersedes: none (rewritten while PROPOSED; the earlier single-host draft was never accepted)
