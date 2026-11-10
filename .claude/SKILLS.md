# Available Skills

This file binds project-specific variable values to skills that accept parameters.
Claude reads this file to know which skills are active and what paths to inject.

**Stack:** Angular (Angular Material) SPA + .NET Web API, reading `ShawCentral.Trace.AuditTrail` (pre-code)

---

## Orchestrator Development Pattern

Skill: `orchestrator-development-pattern` (located at `~/.claude/skills/orchestrator-development-pattern/SKILL.md`)
Trigger: `/orchestrator-development-pattern` or when the user says "start development", "implement", "build".

The orchestrator detects the platform at runtime.

values:
  project-management-doc: "./docs/project-management.md"
  handoff-doc: "./docs/handoff.md"
  source-code-directory: "./"
  revision-file: "./REVISION.md"
  changelog-file: "./CHANGELOG.md"
  snyk-command: "npm audit (in the Angular project folder) AND dotnet list package --vulnerable --include-transitive (in the API folder) — the dotnet command exits 0 even with findings, so read its output"
  test-runbook-location: "./docs/testing/<FEATURE-ID>-<short-name>.md"
  architecture-doc: "./docs/architecture.md"
  test-cases-doc: "./docs/test-cases.md"
  adr-directory: "./docs/adr"
  graphify-directories:
    - "./src"
    - "./tests"
  graphify-out: "./graphify-out"

`graphify-directories` keeps the knowledge graph on the code roots; `source-code-directory`
stays the repo root for platform detection. `scripts/graph.ps1` reads both bindings — change a root
here and nowhere else. The roots above are a placeholder until the code exists: once the projects
are created, narrow them to the real folders (e.g. `./src/LogViewer.Api`, `./src/log-viewer-web`).

---

## Idea Triage

Skill: `idea-triage` (located at `~/.claude/skills/idea-triage/SKILL.md`)
Trigger: `/idea-triage` or when the user presents a new idea before any code exists.

values:
  docs-directory: "./docs"
  prd-file: "./docs/prd.md"
  architecture-file: "./docs/architecture.md"
  project-management-doc: "./docs/project-management.md"
  handoff-doc: "./docs/handoff.md"
  adr-directory: "./docs/adr"

---

## Graph-Assisted Context

One graph of the `graphify-directories` roots, at `graphify-out/`, **built by `scripts/graph.ps1`** —
not by the `/graphify` skill:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/graph.ps1
```

The script reads `graphify-directories` and `graphify-out` above, runs `graphify update` per root
(no LLM) and stamps `GRAPH_REPORT.md` with the commit it was built at. The orchestrator's Graphify
step runs the same script. Only `GRAPH_REPORT.md` is committed; `graph.json`, `graph.html` and the
cache are regenerable and gitignored, so a fresh clone has no graph until the script runs. If the
report's `> Built at commit:` is not `git rev-parse HEAD` and the diff since touches a code root, it
is stale: rebuild before relying on it.

Read `graphify-out/GRAPH_REPORT.md` before starting any feature that touches multiple modules.

Skill: `graphify` (located at `~/.claude/skills/graphify/SKILL.md`)
Trigger: `/graphify query "<topic>"` — to ask the built graph a question. Run `/graphify` over a
root by hand only when the LLM-enriched graph (inferred edges, named communities) is wanted.

---

## Find Skills

Skill: `find-skills` (located at `~/.claude/skills/find-skills/SKILL.md`)
Trigger: `/find-skills` or `/find-skills <query>`

---

## Shared-Path Invariant

idea-triage's `architecture-file` and the orchestrator's `architecture-doc` are the
**same physical file** — idea-triage writes it, the orchestrator reads it — but each
skill names its own variable so either stays usable without the other installed.
The same applies to `project-management-doc`, `handoff-doc`, and `adr-directory`.
If any of these paths changes, change it in **both** blocks, or the two skills will
silently disagree about which file is authoritative.
