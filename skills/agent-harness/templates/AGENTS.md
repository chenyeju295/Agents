# <PROJECT_NAME> — Agent Guide

Short entry point for AI agents. Read [`docs/INDEX.md`](docs/INDEX.md) first,
then navigate to the doc relevant to your task. Keep this file a router, not a
manual.

## Project Overview

<ONE_PARAGRAPH: what this project is, its primary language/build tool, and the
current priority.>

```text
<TOP_LEVEL_LAYOUT: 4-8 lines mapping the real top-level dirs to their purpose>
```

## Fact Priority

When sources conflict, resolve in this order:

```text
Code + dependency manifest        (the running truth)
  > stable/adopted contracts or specs
  > active architecture docs and accepted decisions
  > drafts, planning notes, examples
```

<Note any planning-only assets that do NOT participate in the build, and any
capability that does not yet exist so agents don't describe it as available.>

## Engineering Rules

Hard constraints (Always / Ask First / Never) and the Doc Sync Matrix:
[`docs/rules.md`](docs/rules.md).
Command contracts / how to verify a change: [`docs/commands.md`](docs/commands.md).
Architecture decisions: [`docs/decisions/`](docs/decisions/).

## Task Navigation

| Task | Read first |
|---|---|
| Understand the project / choose where to change | `docs/INDEX.md` |
| <RECURRING_TASK_1> | <DOC> |
| <RECURRING_TASK_2> | <DOC> |
| Complex or multi-session task | `docs/plans/` — create an execution plan |

## Work and Verification

1. Confirm the current fact source and any existing uncommitted changes before editing.
2. For complex tasks, create/update an execution plan under `docs/plans/` first.
3. Only modify files within task scope; log adjacent issues instead of expanding scope.
4. Architecture decisions go into `docs/decisions/`, not just chat or commit messages.
5. Minimum verification before claiming done:

```bash
<SMALLEST_COMMAND_THAT_PROVES_A_CHANGE>
```

Do not describe untested builds or runs as passing.
