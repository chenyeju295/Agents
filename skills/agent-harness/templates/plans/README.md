---
status: active
kind: plan-index
---

# Versioned Execution Plans

Complex tasks carry state across agents, threads, and work sessions via
in-repo plans — no reliance on chat history.

Create from [`TEMPLATE.md`](TEMPLATE.md) (copy of
[PLAN-TEMPLATE.md](../PLAN-TEMPLATE.md) when bootstrapping).

## When to Create a Plan

Create a plan when any of the following apply:

- The change spans multiple modules, layers, or platforms.
- Multiple rounds of implementation and verification are needed.
- Unresolved architectural or product decisions block progress.
- The task may be continued by a different agent or in a new context.

Simple, clearly scoped edits and read-only investigations do not require a plan.

## Naming and Status

Filename: `NNNN-short-kebab-name.md`.

Frontmatter `status` is authoritative (`draft` | `active` | `paused` |
`completed`). Do not add a second status field in the body.

## Selecting and Updating

- Select a plan only when the current task explicitly continues it or its
  unfinished scope clearly matches the requested work.
- Update only the selected `active` plan while executing that work.
- A `completed` plan is historical evidence — do not reopen or sync it with
  later code changes; create a follow-up plan for new complex work.
- Record verification only when it is run; mark outstanding checks explicitly.

## Required Sections

Goal · Scope · Acceptance Criteria · Progress · Decisions · Verification ·
Open Questions
