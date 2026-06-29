# Agent Execution Contract

## Purpose

This repository is developed with AI coding agents. This contract makes agent work predictable, minimal, verifiable, reviewable, and safe for future agents.

Agent-facing documents are navigation aids and execution rules. Source files and executable behavior remain the final source of truth.

## Navigation

| Need | Read |
|---|---|
| Locate ownership and entry files | `docs/agent/project-map.md` |
| Execute a task safely | `docs/agent/execution-harness.md` |
| Plan complex work | `docs/agent/plans/README.md` |
| Adopt or customize the framework | `docs/agent/adoption.md` |
| Understand design rationale | `docs/agent/design-principles.md` |

## Required Workflow

For every task:

1. Read this file.
2. Read `docs/agent/project-map.md`.
3. Read `docs/agent/execution-harness.md`.
4. Classify the task: bugfix, feature, refactor, test, docs, build/config, or dependency change.
5. Decide whether the work needs a versioned execution plan.
6. Identify and inspect the smallest relevant context.
7. Make the smallest correct change.
8. Run verification proportional to the change risk.
9. Update agent-facing documents when future navigation or execution is affected.
10. Report changes, verification, documentation updates, and uncertainty.

## Instruction Scope

This file applies to the whole repository. A nested `AGENTS.md` may add module-specific commands and constraints; the nearest file to an edited path takes precedence. Explicit user instructions remain higher priority.

## Context Rules

Start from the project map and files explicitly named by the task. Expand context only with evidence such as an import, stack trace, failing test, public API use, dependency edge, or build/runtime error.

Do not broadly scan a repository by default. Architecture reviews and map maintenance are valid reasons for broader inspection.

## Planning Rules

Use a checked-in execution plan for work that spans multiple modules, changes a public boundary, introduces a migration, or is expected to require more than one implementation session. Small local changes can use an ephemeral plan.

Versioned plans must record scope, acceptance criteria, progress, decisions, verification, and discovered follow-up work. Move completed plans to the completed directory; do not rewrite history to hide deviations.

## Edit Rules

- Prefer minimal diffs and local fixes.
- Do not combine unrelated cleanup with task work.
- Preserve behavior and public APIs unless the task requires changing them.
- Do not add dependencies or tools without a concrete need.
- Do not manually edit generated files unless their source or generator is updated too.
- Review the final diff for accidental and formatting-only changes.

## Verification Rules

- Run the smallest relevant check first.
- Use broader checks for shared code, public APIs, dependencies, build files, and configuration.
- Never claim a check passed when it was not run.
- If verification is impossible, report the exact reason and remaining risk.

The repository check entry point is:

```bash
bash harness/evaluation/eval.sh quick
```

Use `full` when the configured full checks are warranted.

## Documentation Rules

Update `docs/agent/project-map.md` and `harness/map/project_map.json` when modules, entry points, public boundaries, dependency directions, or common commands change.

Update `docs/agent/update-rules.md` when repeated agent mistakes, verification requirements, protected files, or documentation boundaries change.

Do not invent semantics. Record an evidence-backed TODO when ownership, behavior, or intent cannot be verified.

## Failure Rules

When verification fails:

1. Read the first meaningful error.
2. Classify the failing layer.
3. Re-open the smallest related context.
4. Apply a minimal fix and rerun the failed check.
5. Separate unrelated or pre-existing failures.

Stop and report uncertainty instead of repeatedly patching unrelated files.

## Forbidden Actions

- Large rewrites without explicit scope.
- Hiding verification failures or weakening tests to make them pass.
- Guessing business semantics in agent documentation.
- Changing public APIs without inspecting downstream usage.
- Skipping map updates after structural changes.

## Completion Report

```text
Changed:
- ...

Verified:
- ...

Docs Updated:
- ...

Not Verified:
- ...

Uncertainty / TODO:
- ...
```
