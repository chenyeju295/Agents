---
status: active
kind: checklists
---

# Implementation Checklists

Ordered per-task checklists. Each step links to a doc only when extra context is
needed — follow links on demand, not upfront. Add a checklist when a task type
recurs; do not pre-write ones for tasks nobody does yet.

Every checklist ends with the same two close-out steps: Doc Sync (matching rows
only) and verification selection.

---

## Scoped Change

Use for any implementation, configuration, or documentation change. Keep this
short checklist even when specialized checklists are added later.

- [ ] Read applicable repository and directory-level instructions
- [ ] Inspect the source of truth, current change scope, and Git status/diff
  when version control is available
- [ ] Identify public behavior, contracts, configuration, or inventory affected
- [ ] Make the smallest coherent edit; preserve unrelated changes
- [ ] Review the final diff, including intentional generated or lockfile changes
- [ ] Doc sync: apply only matching rows -> [Doc Sync Matrix](rules.md#doc-sync-matrix)
- [ ] Verify: smallest command from [commands.md](commands.md#command-selection); report anything not run

---

## <TASK_TYPE_1: e.g. New Module / Package>

Use when <trigger condition>.

- [ ] Confirm this is the right task type and the right place for the change → [rules.md](rules.md)
- [ ] Create the unit: <files/structure this project requires>
- [ ] Register it: <dependency manifest / workspace / index wiring>
- [ ] Implement in order: <the ordered steps for this project>
- [ ] Expose public API through the one agreed entry; document it
- [ ] Doc sync: apply only matching rows → [Doc Sync Matrix](rules.md#doc-sync-matrix)
- [ ] Verify: smallest command from [commands.md](commands.md#command-selection) — report anything not run

---

## <TASK_TYPE_2>

Use when <trigger condition>.

- [ ] <step>
- [ ] <step>
- [ ] Doc sync → [Doc Sync Matrix](rules.md#doc-sync-matrix) (matching rows only)
- [ ] Verify → [commands.md](commands.md#command-selection) — report anything not run
