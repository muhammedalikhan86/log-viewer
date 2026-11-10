---
name: run-app
description: Launch this project's app locally and verify it comes up. Use when asked to run, start, serve, or smoke-check the app, or to confirm a change works in the real app rather than only in tests.
---

# Run the log viewer locally

The app is planned as two halves: an Angular (Angular Material) front end and a .NET Web API that
reads `ShawCentral.Trace.AuditTrail` through the read-only `DatabaseReader` login. **No code exists
yet** (as of the ADLC scaffold), so none of the commands below have been verified. Update this file
from the real manifests once the projects are created.

## 1. Detect before starting

Never trust paths written here — re-derive them each time:

1. Find the API: `find . -name "*.csproj" -not -path "*/node_modules/*"` and read its
   `Properties/launchSettings.json` for the URL and port.
2. Find the SPA: the folder holding `angular.json`. Read `package.json` `scripts` for the start
   command, and `proxy.conf.json` (if any) for the API URL it forwards to.
3. If a `Makefile` or wrapper script appears later, it becomes the entrypoint — use it, and record
   the raw command it replaces as the one *not* to run.
4. If one half is missing, say so. Do not scaffold it unasked.

## 2. Prerequisites — check and warn before starting

1. `dotnet --version` matches the `TargetFramework` in the `.csproj`.
2. `node --version` suits the Angular version in `package.json`.
3. SPA dependencies installed (`node_modules` present). If not, suggest the install command the
   repo uses (`npm ci` when a lockfile exists) — do not run it unasked.
4. The database is reachable: `idb_ag.shawstock.com.au,4433`, login `DatabaseReader`. A quick check:
   `sqlcmd -S "idb_ag.shawstock.com.au,4433" -U DatabaseReader -P "<password>" -d ShawCentral -C -Q "select top 1 1 from Trace.AuditTrail"`.
   Never print the password or connection string in output.

## 3. Start order

Start the API first, then the SPA. The Angular dev-server proxy fails its first requests if the
API is not listening yet.

## 4. Verify, don't assume

1. `curl` the API's health or log endpoint on the port from `launchSettings.json`.
2. `curl` the SPA's dev-server URL. A dev server that fails to compile never binds, so "process
   still running" is not proof.

## 5. Report

The URLs that answered, plus warnings that look harmless but are not: compile warnings, CORS or
proxy errors, SQL connection or certificate errors.

## 6. Fast-iteration path

None yet. If one appears (for example `dotnet watch` beside `ng serve`), document it here: what to
run, which ports change, and what to stop first.

## Guardrails

1. Don't scaffold a missing half unasked.
2. Suggest the install command; don't assume one.
3. Never kill an existing listener to free a port — report it and ask.
4. The app is read-only against `ShawCentral`. Never run any SQL that writes, and never apply a
   migration as part of "starting the app".
