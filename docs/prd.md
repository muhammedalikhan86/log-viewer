# PRD: Log Viewer

> Status: APPROVED
> Version: v9
> Last updated: 2026-11-10
> Phase 0 (Discovery): not applicable — the incumbent is ad-hoc querying of the central logs by
> developers; there is no business process to discover.

## Problem Statement

Shaw's internal applications write three kinds of log to one central place:

- **Audit events** — what an application did: imports, logins, queries, creates, updates, exports,
  deletes. About 437,000 events from 19 applications over the past year; up to roughly 9,000 on a
  busy day.
- **Errors** — failures an application hit. About 5,000 in the past month.
- **Information messages** — routine progress messages. About 219,000 in the past month.

Today the only way to see any of these is to write a database query by hand. That limits who can
look (only people with database access and query skills), slows down investigating a problem, and
makes it hard to answer simple questions like "what did this application do in the last hour?",
"did today's import succeed?" or "is it failing right now?".

The experience wanted is a modern log-search screen: one search box, a time range, a chart of log
volume over that time, a filter panel showing counts per application, level and server, and a list
of entries with matches highlighted — plus a live mode that keeps the list moving as entries
arrive.

## Goals

- Developers and support staff can see any application's audit events, errors and information
  messages without writing a query.
- An investigation that starts with "what happened in application X around time T" is answered in
  seconds, with all three kinds of log for that moment in one place.
- People can watch an application's activity as it happens, not only look back at it.
- Errors and events flagged as important stand out, so problems are noticed rather than found by
  accident.
- A spike or gap in activity is visible at a glance, before reading a single entry.
- The viewer never changes the logs. It only reads.

## Non-Goals

- Changing, deleting or annotating log entries.
- Changing how applications write their logs.
- Limiting which applications a user may see — in v1 every permitted user sees every application.
- Alerting or notifications when something goes wrong.
- Long-term reporting or trend dashboards.
- Keeping a copy of the logs inside the viewer, or managing how long logs are kept. History is
  managed outside this project; the viewer shows whatever is there.

## User Stories

- US-1: As a developer or support person, I want to pick one or more applications and see their
  log entries, newest first, so that I can see what they have been doing.
- US-2: As a developer or support person, I want every entry to show a level (error, important,
  information, routine audit) with a colour, and to filter by level, so that I can focus on what
  matters for the problem in hand.
- US-3: As a developer or support person, I want to choose a time range — a quick preset like "last
  hour" or exact from/to times — so that I see only the period I care about.
- US-4: As a developer or support person, I want to filter by server, action type and user, so that
  I can find the entries behind a reported problem.
- US-5: As a developer or support person, I want one search box over the text of every entry, with
  my search words highlighted in the results, so that I can find a specific batch, record or
  message quickly.
- US-6: As a developer or support person, I want a chart of how many entries were logged over the
  chosen time range, broken down by application, so that I can spot spikes and silences.
- US-7: As a developer or support person, I want a filter panel that shows how many entries each
  application, level and server has in the current results, and lets me click one to filter, so
  that I can narrow down without typing.
- US-8: As a developer or support person, I want to switch between one line per entry and the full
  text of every entry, and to open any single entry in full, so that long errors are readable.
- US-9: As a developer or support person, I want a live mode that keeps showing new entries as they
  arrive, so that I can watch an application while a job runs or a problem is happening.
- US-10: As a developer or support person, I want to see, at a glance, when each application last
  logged and how many errors it has had recently, so that I can spot one that has gone quiet or
  started failing.
- US-11: As a developer or support person, I want to copy a link to exactly what I am looking at,
  so that I can send a colleague straight to the same entries.
- US-12: As a developer or support person, I want to save my current filters, search and time
  range as a named view and open it again later, so that checks I do often take one click.
- US-13: As a developer or support person, I want to share one of my saved views with the rest of
  the group, so that colleagues can use the same checks. Views I do not share stay private to me.

## Success Metrics

- The entries behind a reported problem are found in under 2 minutes.
- A filtered view of one application's entries appears in under 2 seconds.
- In live mode, a new entry appears within 30 seconds of being logged.
- Support staff never need to ask a developer to run a query to answer "what happened in app X".

## Constraints & Assumptions

- The viewer reads the existing central logs as they are today. It must not change them.
- Access to the logs is read-only and approved for internal use.
- Entries contain the identity of the staff member who did each action, so the viewer shows
  personal data. Only members of the **Development Team - Sydney** and **IT Team** groups may open
  the viewer. Everyone permitted sees every application.
- Internal staff only; not available outside Shaw.
- How far back each kind of log goes is managed by the IT team, outside this project. The viewer
  shows whatever is in the central logs at the time. Today that is about a year of audit events and
  about a month of errors and information messages.
- Saved views are the one thing the viewer keeps of its own. They hold filter settings only, never
  copies of log entries.

## Open Questions

| ID | Question | Owner | Resolved? |
|----|----------|-------|-----------|
| Q1 | Who will use this, and should everyone see every application's entries? | Muhammed Ali Khan | Yes — developers and support staff; every application visible to everyone permitted |
| Q2 | Audit events only, or errors and information messages too? | Muhammed Ali Khan | Yes — all three in v1 |
| Q3 | Main use: investigating past problems, watching live, or both? | Muhammed Ali Khan | Yes — both |
| Q4 | Are alerting and trend reporting out for v1? | Muhammed Ali Khan | Yes — both out |
| Q5 | Which named group may open the viewer? | Muhammed Ali Khan | Yes — Development Team - Sydney and IT Team (no group named "IT Developers" exists) |
| Q6 | How long must errors and information messages be kept? | Muhammed Ali Khan | Yes — not this project's concern; the viewer shows what is there |
| Q7 | Who owns the central logs and how long they are kept? | Muhammed Ali Khan | Yes — the IT team (not developers) |
| Q8 | Are saved views wanted in v1, or is a shareable link enough? | Muhammed Ali Khan | Yes — saved views in v1, as well as the link |
| Q9 | Are saved views private to each person, or shared with the whole group? | Muhammed Ali Khan | Yes — private by default; the owner can share one with the group |

## Version History

| Version | Date | Change | Triggered By | Approved By |
|---------|------|--------|---------------|-------------|
| v1 | 2026-11-10 | Initial draft | — | — |
| v2 | 2026-11-10 | Resolved Q1–Q3: all three log kinds in scope; live watching added; everyone sees every app. Added US-2, US-6, US-8; reworked goals; added Q5, Q6 | Triage edit | — |
| v3 | 2026-11-10 | Resolved Q4 (alerts and dashboards out). Access limited to a named group. Longer error/info history needed, recorded as an outside dependency. Reworked stories to the wanted search-screen experience: levels, time presets, volume chart, filter panel with counts, highlighting, expand/collapse, shareable link. Added Q7, Q8 | Triage edit | — |
| v4 | 2026-11-10 | Resolved Q6–Q8: log history is managed by the IT team outside this project, so the retention need was removed; saved views added (US-12). Added Q9 | Triage edit | — |
| v5 | 2026-11-10 | Resolved Q5 (access: IT Developers group) and Q9 (saved views private by default, shareable with the group — US-13) | Triage edit | — |
| v6 | 2026-11-10 | Set success metric targets: 2 minutes to find, 2 seconds to load, 10 seconds live delay, no developer queries | Triage edit | — |
| v7 | 2026-11-10 | PRD approved | Gate approval | Muhammed Ali Khan |
| v8 | 2026-11-10 | Access groups corrected: no "IT Developers" group exists; access is Development Team - Sydney and IT Team | Upward ripple from Architecture v1 | — |
| v9 | 2026-11-10 | Live-mode delay target relaxed from 10 to 30 seconds to keep load on the shared database low | Upward ripple from Architecture v4 | — |
