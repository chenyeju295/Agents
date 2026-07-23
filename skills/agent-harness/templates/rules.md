---
status: active
kind: rules
---

# Agent Engineering Rules

Cross-task hard constraints. Project map: [`docs/INDEX.md`](../docs/INDEX.md)
(or [`INDEX.md`](INDEX.md) if this file lives under `docs/`).

Fill each list with rules the code **actually follows**. Delete placeholders
and Git-specific lines that do not apply. Aspirational rules erode trust — only
write what is enforced.

Boundaries use the three-tier pattern common in agent instruction guides:
**Always** / **Ask First** / **Never**.

## Always

- Read applicable root and nested agent instructions before editing.
<!-- Keep the next two lines only for repositories using Git. -->
- In a Git repository, inspect `git status --short` and the relevant diff before
  editing; preserve pre-existing changes of uncertain ownership.
- Keep edits within the requested scope; review the final diff for unrelated
  changes, generated artifacts, secrets, and accidental formatting churn.
- <e.g. classify where a change belongs before editing>
- <e.g. cross-boundary errors carry a diagnosable cause; never swallow silently>
- <e.g. public API is documented / exported through the one agreed entry>
- Run the minimum verification in [`commands.md`](commands.md) and report what was not checked.

## Ask First

<!-- Keep the next two lines only for repositories using Git. -->
- <e.g. create a commit, push, publish, or open a pull request when the project
  requires explicit authorization>
- <e.g. run a history-rewriting or destructive Git operation>
- <e.g. delete or rename a public module/package>
- <e.g. change supported platforms / runtime targets>
- <e.g. introduce a workspace-wide framework dependency>
- <e.g. change the layering model, dependency direction, or error model>

## Never

<!-- Keep the next line only for repositories using Git. -->
- Use destructive Git commands (`reset --hard`, `clean -fd`, discard checkout,
  or force-push) without explicit authorization.
- <e.g. reverse the dependency direction / import another module's internals>
- <e.g. treat a draft/planning asset as an implemented capability>
- <e.g. claim a non-existent tool/generator/build is available>
- <e.g. modify files outside task scope or overwrite changes of uncertain ownership>
- Describe untested builds or runs as passing.

## Git and Change Scope

Use this section only if the repository uses Git; otherwise replace it with the
equivalent version-control practice or remove it.

1. Start by observing the working tree. A dirty tree is normal and does not
   authorize reverting, staging, or rewriting another contributor's changes.
2. Use scoped diffs while working, then inspect the final diff before reporting
   completion. Explain any intentional generated or lockfile changes.
3. Separate implementation from delivery. Do not assume permission to stage,
   commit, push, tag, or create a pull request unless project instructions or
   the requester authorize it.
4. Treat history rewrites, cleanup that removes untracked files, force pushes,
   and remote mutations as explicit-approval operations.

## Doc Sync Matrix

Apply this matrix when a change alters **public capabilities, workspace
inventory, adopted contracts, architecture decisions, or migration status**.

Do **not** trigger doc sync for: internal refactors, private implementation
changes, tests, formatting, or bug fixes that preserve documented behavior.

Build/workspace mutations (e.g. editing the dependency manifest) belong in the
task checklist when they are mechanical steps — this matrix lists
**documentation** targets only.

| Change type | Docs to update |
|---|---|
| New public module / package / service | module index; status/inventory doc |
| Module renamed or deleted | every index/status/spec row that referenced it |
| New or renamed public API / interface | API reference or quick-reference table |
| Contract/spec status change (draft→active→stable) | spec index; status doc |
| Architecture decision (layering / deps / error model) | new ADR + decision index; sync the active architecture doc |
| Indexed documentation added, moved, or deprecated | `docs/INDEX.md` |
| Multi-session task progressed | the **active** plan file's Progress + Verification |

Fill the left column with the change types that actually recur in this project.
This matrix is the keystone against doc-code drift — consult it at close-out,
do not treat "keep docs updated" as a vague virtue.

## Authoritative Location

Each rule lives in exactly one place; other docs link here rather than
restating it. When a rule changes, change it here.
