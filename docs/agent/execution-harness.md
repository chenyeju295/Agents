# Execution Harness

## Purpose

This protocol defines how an AI coding agent moves from a task to a verified change without treating the repository as an unknown blank codebase.

## 1. Task Protocol

Classify the task before editing:

| Type | Starting evidence | Minimum completion condition |
|---|---|---|
| Bugfix | Error, regression, failing test | Cause explained and focused verification passed |
| Feature | Requested behavior and owning module | Behavior implemented, tested where practical, boundaries documented |
| Refactor | Explicit structural scope | Behavior preserved and broader verification passed |
| Test | Missing or incorrect coverage | Target test and related group passed |
| Docs | Verified repository facts | Documentation matches current behavior |
| Build/config | Command, environment, CI, or dependency change | Relevant resolution/build check passed |

Do not mix task types merely because adjacent cleanup is convenient.

### Planning threshold

Create a versioned plan from `docs/agent/plans/_template.md` when any condition is true:

- the change crosses module boundaries
- a public API, data format, dependency direction, or migration changes
- completion requires several independently verifiable milestones
- another Agent or future session must be able to resume the work

Keep small, reversible, single-area work on an ephemeral plan.

## 2. Context Protocol

Inspect in this order:

1. `AGENTS.md`.
2. `docs/agent/project-map.md`.
3. Files directly named by the task.
4. Files connected by imports, tests, stack traces, public API usage, or configuration.
5. Broader searches only when the evidence above is insufficient.

The optional context loader returns candidates, not permission to assume their contents are correct. Confirm important claims against source files.

Nested `AGENTS.md` files refine instructions for their directory subtree. Inspect the nearest applicable file before editing a module, and keep repository-wide policy in the root file.

## 3. Edit Protocol

Before editing, identify the owning area, smallest file set, nearby conventions, and protected/generated status.

During editing, preserve unrelated behavior, avoid formatting churn, and keep new abstractions or dependencies justified by the task.

After editing, inspect the diff, remove accidental changes, verify by risk, and update navigation documents when future work is affected.

## 4. Verification Protocol

| Change risk | Expected verification |
|---|---|
| Local docs or implementation | Targeted check, then static analysis if relevant |
| Shared/core behavior | Targeted plus broader related checks |
| Public API or boundary | Downstream usage search, related tests, map update |
| Build/config/dependency | Resolution/install and build-equivalent check |
| Harness protocol or runner | Consistency review plus runner success/failure paths |

`harness/evaluation/checks.json` is the executable verification registry. Each check declares an ID, command, and whether it runs in `quick` or `full` mode.

Checks should emit compact, actionable output. A failing invariant should name the affected artifact and the expected remediation whenever possible.

## 5. Documentation Protocol

Update Agent documentation only when a change affects future navigation, execution, verification, or safety. Keep facts concise and operational.

When intent cannot be proven, use:

```text
TODO(agent-docs):
- [ ] Clarify ...
- Evidence:
  - path or observed behavior
- Reason:
  - why this cannot be safely inferred
```

## 6. Failure Protocol

Read the first meaningful error, determine whether it is caused by the current change, reopen the smallest related context, apply a focused fix, and rerun that check.

Stop expanding scope when the source is outside the task, the environment is unavailable, repeated fixes do not change the failure, or product intent is required.

## 7. Completion Protocol

Every handoff must distinguish changed work, successful verification, documentation updates, checks not run, and remaining uncertainty. A missing check is not a passing check.

For a versioned plan, update progress and decisions before the handoff so the repository—not chat history—contains the resumable state.
