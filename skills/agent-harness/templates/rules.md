---
status: active
kind: rules
---

# Agent Engineering Rules

Cross-task hard constraints. Project map: [`INDEX.md`](INDEX.md).

Fill each list with rules the code **actually follows**. Delete placeholders you
do not need. Aspirational rules erode trust — only write what is enforced.

## Always

- <e.g. classify where a change belongs before editing>
- <e.g. cross-boundary errors carry a diagnosable cause; never swallow silently>
- <e.g. public API is documented / exported through the one agreed entry>
- Run the minimum verification in [`commands.md`](commands.md) and report what was not checked.

## Ask First

- <e.g. delete or rename a public module/package>
- <e.g. change supported platforms / runtime targets>
- <e.g. introduce a workspace-wide framework dependency>
- <e.g. change the layering model, dependency direction, or error model>

## Never

- <e.g. reverse the dependency direction / import another module's internals>
- <e.g. treat a draft/planning asset as an implemented capability>
- <e.g. claim a non-existent tool/generator/build is available>
- <e.g. modify files outside task scope or overwrite changes of uncertain ownership>
- Describe untested builds or runs as passing.

## Doc Sync Matrix

**Not optional.** After every code change, update the mapped docs. An
out-of-date doc is a trap for the next agent. Fill the left column with the
change types that actually recur in this project.

| Change type | Docs to update |
|---|---|
| New public module / package / service | module index; dependency manifest; status/inventory doc |
| New public API / interface | API reference or quick-reference table |
| Contract/spec status change (draft→active→stable) | spec index; status doc |
| Architecture decision (layering / deps / error model) | new ADR in `decisions/` |
| Multi-session task progressed | the plan file's Progress + Verification |
| Module renamed or deleted | every doc above that referenced it |

## Authoritative Location

Each rule lives in exactly one place; other docs link here rather than restating
it. When a rule changes, change it here.
