---
status: active
kind: commands
---

# Command Guide

Command contracts for repeatable local work. Defines the expected tool surface
so agents verify changes with the smallest command that proves them, instead of
inventing command names or over-running full builds.

Exact, runnable commands (with flags) are high-signal for agents — list only
commands that exist and have been run successfully. Do not list planned
commands as available. Replace every sample row below with a real command or
delete it; never leave angle-bracket placeholders in an installed harness.

## Current Commands

| Command | Status | Use |
|---|---|---|
| `<install/restore deps>` | available | Refresh dependencies / lockfile |
| `<static analysis / lint>` | available | Primary correctness gate |
| `<unit tests>` | available | Run when a `test` dir exists for the changed scope |
| `<build>` | <available/planned> | Full build — only when explicitly required |

## Command Selection

Use the smallest command that proves the change:

| Change | Preferred verification |
|---|---|
| Single module implementation | analysis (+ tests if present) scoped to that module |
| Cross-module or final gate | workspace-wide analysis + tests |
| Docs-only change | none / link check |

Avoid repeated workspace-wide runs after a narrower command already proved the
modified scope, unless the task crosses module boundaries.

For a Git repository, inspect `git status --short` and the relevant `git diff`
as change evidence; these observations complement, but do not replace,
verification. Do not list a Git operation as a required project gate unless the
repository actually enforces it.

When reporting done, state the command, scope, and result, then state exactly
what was not run. Do not describe untested builds, deployments, simulator runs,
or device runs as passing.

## Script Standards (if/when scripts are added)

- Runnable from the repository root.
- Fail non-zero on real validation failures; do not hide unrelated failures.
- Do not modify docs except explicit generator commands whose purpose is doc output.
- Avoid simulator/device/network/production work unless the name makes that cost explicit.
