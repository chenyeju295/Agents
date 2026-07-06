---
status: active
kind: index
---

# Project Map & Knowledge Index

The single source of navigation — answers "where do I find X". Agent entry
point is [`AGENTS.md`](../AGENTS.md).

## Fact Priority

| Priority | Asset | Notes |
|---|---|---|
| 1 | Code + dependency manifest | The running implementation and real deps |
| 2 | Stable contracts/specs | Adopted public contracts |
| 3 | Active architecture docs + accepted ADRs | Current rules and decisions |
| 4 | Drafts / planning notes | Not yet implemented |

## Path Map

| Path | Purpose |
|---|---|
| `<dir>/` | <purpose> |
| `docs/decisions/` | Accepted architecture decisions (ADRs) |
| `docs/plans/` | Multi-session execution plans |

## Navigation by Task

| Task | Read first |
|---|---|
| Understand the project | [Architecture / overview doc](<path>) |
| <RECURRING_TASK> | <doc> |
| Multi-session / complex task | [Plans](plans/) |

## Document Directory

| Document | Status | Kind |
|---|---|---|
| [Rules](rules.md) | active | rules |
| [Commands](commands.md) | active | commands |
| [Checklists](checklists.md) | active | checklists |
| [Pitfalls](pitfalls.md) | active | pitfalls |
| [Decisions](decisions/) | active | decision-index |
| [Plans](plans/) | active | plan-index |

## Status Definitions

- `draft`: candidate/unimplemented — must not be treated as a current capability.
- `active`: currently adopted or in active implementation.
- `stable`: used in practice; public contracts evolve compatibly.
- `accepted`: ADRs — in force; superseded by a newer ADR, never edited in place.
- `deprecated`: retained for context only.

## Maintenance

- Update this index when docs are added, moved, or deprecated.
- Each rule has exactly one authoritative location; other places link to it.
- Architecture trade-offs go into ADRs; complex task state goes into plans.
