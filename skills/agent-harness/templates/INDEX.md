---
status: active
kind: index
---

# Project Map & Knowledge Index

The single source of navigation — answers "where do I find X". Agent entry
point is [`AGENTS.md`](../AGENTS.md). Keep this file the map; keep
`AGENTS.md` the short router that points here.

## Fact Priority

| Priority | Asset | Notes |
|---|---|---|
| 1 | Code + dependency manifest | The running implementation and real deps |
| 2 | Stable contracts/specs | Adopted public contracts |
| 3 | Active architecture docs + accepted ADRs | Current rules and decisions |
| 4 | Drafts / planning notes | Not yet implemented — must not be treated as shipped |

Write the full priority table **here once**. `AGENTS.md` links to this
section; do not maintain two copies.

## Path Map

| Path | Purpose |
|---|---|
| `<dir>/` | <purpose> |
| `<HARNESS_DIR>/` | Agent rules, checklists, commands, pitfalls |
| `docs/decisions/` | Accepted architecture decisions (ADRs) |
| `docs/plans/` | Multi-session execution plans |
| `<Optional: skills/>` | Project workflow Skills (multi-step entry points) |

## Navigation by Task

| Task | Read first |
|---|---|
| Understand the project / choose where to change | `<architecture / overview>` |
| <RECURRING_TASK> | `<doc or Skill → doc>` |
| Multi-session / complex task | [Plans](plans/README.md) |
| Look up status / public API inventory | `<status / inventory doc>` |

This table can be longer than the short routes in `AGENTS.md`. Prefer linking
to Skills or checklists for multi-step work instead of inlining steps here.

## Document Directory

| Document | Status | Kind |
|---|---|---|
| [`<HARNESS_DIR>/rules.md`](../<HARNESS_DIR>/rules.md) | active | rules |
| [`<HARNESS_DIR>/commands.md`](../<HARNESS_DIR>/commands.md) | active | commands |
| [`<HARNESS_DIR>/checklists.md`](../<HARNESS_DIR>/checklists.md) | active | checklists |
| [`<HARNESS_DIR>/pitfalls.md`](../<HARNESS_DIR>/pitfalls.md) | active | pitfalls |
| [Decisions](decisions/README.md) | active | decision-index |
| [Plans](plans/README.md) | active | plan-index |

Adjust paths if the project keeps rules under `docs/` instead of `harness/`.

## Status Definitions

- `draft`: candidate/unimplemented — must not be treated as a current capability.
- `active`: currently adopted or in active implementation.
- `stable`: used in practice; public contracts evolve compatibly.
- `paused` / `completed`: execution plans only — on hold, or historical evidence.
- `accepted`: ADRs — in force; superseded by a newer ADR, never edited in place.
- `deprecated` / `reference`: retained for context only.

## Maintenance

- Update this index when docs are added, moved, or deprecated.
- Each rule has exactly one authoritative location; other places link to it.
- Architecture trade-offs go into ADRs; complex task state goes into plans.
- Prefer mechanical drift checks (inventory vs code, dangling links) over
  aspirational "keep docs updated" reminders — see the skill's audit workflow.
