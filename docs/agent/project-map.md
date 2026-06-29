# Agent Project Map

## Purpose

This is the concise, human-readable map for Agent Harness Engineering. It describes the repository as it exists now, not a future product or sample application.

## Project Overview

| Field | Value |
|---|---|
| Project | Agent Harness Engineering |
| Purpose | Reusable execution framework for AI coding agents |
| Runtime | Bash and Dart for optional automation |
| Source of truth | Repository files and executable behavior |
| Current stage | Stage 0 protocol with lightweight automation |

## Repository Layout

| Path | Role | Main entry |
|---|---|---|
| `AGENTS.md` | Mandatory Agent contract | `AGENTS.md` |
| `docs/agent/` | Human-readable navigation, principles, adoption, and protocols | `project-map.md`, `execution-harness.md`, `design-principles.md`, `adoption.md` |
| `docs/agent/plans/` | Versioned plans for complex, resumable work | `README.md`, `_template.md`, `active/`, `completed/` |
| `harness/map/` | Machine-readable repository navigation | `project_map.json` |
| `harness/runtime/` | Context selection automation | `context_loader.dart` |
| `harness/evaluation/` | Configurable verification and structural self-checks | `checks.json`, `eval.sh`, `harness_lint.dart` |
| `harness/evolution/` | Reviewed failure knowledge and raw records | `rules.json`, `failure_log.jsonl` |

## Boundary Index

| Area | Boundary | Downstream users |
|---|---|---|
| Agent protocol | `AGENTS.md` | All coding agents |
| Human navigation | `docs/agent/project-map.md` | Agents and maintainers |
| Machine navigation | `harness/map/project_map.json` | Context loader and future tooling |
| Verification configuration | `harness/evaluation/checks.json` | Evaluation runner |
| Verification execution | `harness/evaluation/eval.sh` | Agents and CI |
| Structural invariants | `harness/evaluation/harness_lint.dart` | Verification runner and maintainers |
| Complex work state | `docs/agent/plans/` | Agents across sessions |

## High-Risk Areas

| Area | Risk | Required check |
|---|---|---|
| `AGENTS.md` | Changes every Agent task | Review all agent docs for consistency |
| Project maps | Stale navigation misdirects future work | Compare Markdown and JSON maps to the filesystem |
| `checks.json` | Commands execute in the repository | Validate JSON and run `eval.sh quick` |
| `eval.sh` | False pass/fail claims undermine the harness | Run both success and controlled failure paths |
| Context loader schema | Map changes can break discovery | Analyze and run a representative query |
| Harness linter | A false pass permits documentation or configuration drift | Run positive and controlled negative fixtures |

## Generated / Protected Files

No generated files are currently tracked. Verification logs under `harness/logs/` are runtime artifacts and must not be committed.

## Common Commands

```bash
# Find candidate context
dart run harness/runtime/context_loader.dart "task description"

# Run required lightweight verification
bash harness/evaluation/eval.sh quick

# Run all configured verification
bash harness/evaluation/eval.sh full
```

## Current Agent Signals

| Signal | Area |
|---|---|
| workflow, contract, completion | Agent protocol |
| map, context, discovery | Project navigation |
| check, verify, test, build | Evaluation |
| failure, rule, learning | Evolution |
| plan, milestone, decision, migration | Execution plans |

## TODO for Future Agents

- [ ] Define a versioned distribution/package format after Stage 0 stabilizes.
- [ ] Add benchmark tasks that measure context precision and successful task completion.
- [ ] Define a versioned compatibility policy for future schema changes.
