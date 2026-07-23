---
status: active
kind: index
---

# <HARNESS_DIR>/

Agent engineering assets for cross-task constraints and implementation
workflows. Optional when rules/checklists/commands live under `docs/` instead.

## Responsibility Boundaries

- `rules.md` — durable constraints (Always / Ask First / Never) + Doc Sync
  Matrix. If a rule should apply across tasks, put it there once and link.
- `checklists.md` — ordered task steps. Reference rules; do not redefine them.
- `commands.md` — repeatable command contracts and verification scope.
- `pitfalls.md` — known failure modes too specific for global rules
  (symptom → root cause → fix).
- Root `AGENTS.md` stays a short entry point; `docs/INDEX.md` stays the map.

IDE-only overlays (e.g. `.cursor/rules/`) may add behavioral hints. Durable
project facts and cross-agent rules still belong here or in `docs/` — do not
duplicate them into IDE overlays.

| File | Purpose |
|---|---|
| [rules.md](rules.md) | Hard constraints + Doc Sync Matrix |
| [checklists.md](checklists.md) | Ordered per-task checklists |
| [commands.md](commands.md) | Command contracts / verification selection |
| [pitfalls.md](pitfalls.md) | Documented traps |

**When to read what:** constraints and doc-sync → `rules.md`; step-by-step →
`checklists.md`; known traps before touching a risky area → `pitfalls.md`;
smallest proving command → `commands.md`.

Project-wide navigation: [`docs/INDEX.md`](../docs/INDEX.md). Agent entry:
[`AGENTS.md`](../AGENTS.md).
