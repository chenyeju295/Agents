# <PROJECT_NAME> — Agent Guide

Short entry point for coding agents (~100 lines). Use this file for start-up
discipline only — it is a **map / table of contents**, not a manual. Detailed
rules live in [`<HARNESS_DIR>/`](<HARNESS_DIR>/); project navigation lives in
[`docs/INDEX.md`](docs/INDEX.md).

Complements human-facing `README.md` ([AGENTS.md](https://agents.md/) open
format). Prefer links over restating README or architecture docs.

## Project Overview

<ONE_PARAGRAPH: what this project is, its primary language/build tool, and the
current priority.>

```text
<TOP_LEVEL_LAYOUT: 4-8 lines mapping the real top-level dirs to their purpose>
```

<Optional one-liner: dependency / ownership direction if the repo has layers
(e.g. `interface -> domain -> infrastructure`). Link the full model; do not
restate it.>

## Fact Priority

When conflicts arise, follow the authority order in
[`docs/INDEX.md`](docs/INDEX.md#fact-priority): code and the dependency
manifest first, then stable contracts/specs, then active architecture docs and
ADRs, then drafts / planning assets.

<Note any planning-only assets that do NOT participate in the build, and any
capability that does not yet exist so agents don't describe it as available.>

## Engineering Rules

Read these by intent, not all upfront:

| Need | Source |
|---|---|
| Hard constraints, boundaries, doc sync | [`<HARNESS_DIR>/rules.md`](<HARNESS_DIR>/rules.md) |
| Git and change-scope expectations | [`<HARNESS_DIR>/rules.md`](<HARNESS_DIR>/rules.md#git-and-change-scope) |
| Step-by-step task flow | [`<HARNESS_DIR>/checklists.md`](<HARNESS_DIR>/checklists.md) |
| Commands and verification scope | [`<HARNESS_DIR>/commands.md`](<HARNESS_DIR>/commands.md) |
| Known traps (symptom → cause → fix) | [`<HARNESS_DIR>/pitfalls.md`](<HARNESS_DIR>/pitfalls.md) |
| Architecture decisions | [`docs/decisions/`](docs/decisions/) |
| <Optional: project workflow Skills> | [`skills/INDEX.md`](skills/INDEX.md) |

`<HARNESS_DIR>` is usually `harness/` or `docs/` — keep whatever the repo
already uses; do not reorganize just to match a template.

## Task Navigation

For the full task map, use [`docs/INDEX.md`](docs/INDEX.md#navigation-by-task).
Common agent routes:

| Task | Start with |
|---|---|
| Choose where a change belongs | `<architecture / overview doc>` |
| <RECURRING_TASK_1> | `<DOC or Skill → DOC>` |
| <RECURRING_TASK_2> | `<DOC>` |
| Cross-module or multi-session work | `<plan Skill or docs/plans/>` |
| Look up an existing API / status | `<status / inventory doc>` |

Keep this table short (≈5–8 rows). The full map belongs in `docs/INDEX.md`.

## Work and Verification

1. Before implementing complex work, select or create **one** current active
   Plan under `docs/plans/` (use a plan-lifecycle Skill if the project has one).
2. At close-out, use the relevant checklist or Skill and apply only matching
   rows from the [Doc Sync Matrix](<HARNESS_DIR>/rules.md#doc-sync-matrix).
3. Select verification from
   [`<HARNESS_DIR>/commands.md`](<HARNESS_DIR>/commands.md#command-selection)
   and report exactly what was not run. Do not describe untested builds,
   simulator runs, or device runs as passing.

<!--
Monorepo note (optional): some agents also read nested AGENTS.md closer to the
edited path ([agents.md](https://agents.md/)). Prefer one root router + docs/
unless a subpackage truly needs different Always/Never rules — then keep the
nested file short and link upward for shared constraints.
-->
