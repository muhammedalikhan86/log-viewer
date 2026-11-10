# ADR-002: Windows authentication, with access limited to two AD groups

> Status: ACCEPTED
> Date: 2026-11-10
> Architecture: docs/architecture.md (v6)

## Context

Logs contain staff identities, so the PRD limits access to two groups: `Development Team - Sydney`
and `IT Team`. Everyone permitted sees every application. Users are on the Shaw domain.
`WebApis\PhoenixV3WebAPI\Phoenix.WebAPI` already uses Negotiate (Windows) authentication with a
fallback policy that requires an authenticated user, and `Shaw.ActiveDirectory` for role checks.

## Decision

Authenticate every request with Windows (Negotiate) authentication and authorise it with one policy
that requires membership of `Development Team - Sydney` or `IT Team`, checked through
`Shaw.ActiveDirectory`, with the group names in configuration.

## Alternatives Considered

| Option | Why not chosen |
|--------|-----------------|
| Entra ID / OIDC sign-in | Not the estate pattern for internal APIs; adds an app registration for no gain on-network |
| Per-application permissions | Out of scope per PRD (everyone permitted sees every app) |
| No auth (network only) | Logs contain personal data |

## Consequences

- Users never see a login screen on a domain machine.
- Group names live in `appsettings.json`, so adding a group is a config change.
- Group lookups are cached per user for a short time to avoid an AD call per request.
- Access depends on AD group membership being kept right by the IT Team.

## Related

- Architecture section: §3 LogViewer API, §6 NFR-004, §9
- Supersedes: none
