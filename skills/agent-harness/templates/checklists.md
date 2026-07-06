---
status: active
kind: checklists
---

# Implementation Checklists

Ordered per-task checklists. Each step links to a doc only when extra context is
needed — follow links on demand, not upfront. Add a checklist when a task type
recurs; do not pre-write ones for tasks nobody does yet.

---

## <TASK_TYPE_1: e.g. New Module / Package>

Use when <trigger condition>.

- [ ] Confirm this is the right task type and the right place for the change → [rules.md](rules.md)
- [ ] Create the unit: <files/structure this project requires>
- [ ] Register it: <dependency manifest / workspace / index wiring>
- [ ] Implement in order: <the ordered steps for this project>
- [ ] Expose public API through the one agreed entry; document it
- [ ] Doc sync: <which docs> → [Doc Sync Matrix](rules.md#doc-sync-matrix)
- [ ] Verify: <command from commands.md> — report anything not run

---

## <TASK_TYPE_2>

Use when <trigger condition>.

- [ ] <step>
- [ ] <step>
- [ ] Doc sync → [Doc Sync Matrix](rules.md#doc-sync-matrix)
- [ ] Verify → [commands.md](commands.md)
