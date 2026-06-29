# Harness Internals

`harness/` contains the machine-readable map and lightweight automation behind the repository's Agent execution contract.

```text
harness/
  map/project_map.json          structured navigation data
  runtime/context_loader.dart   task-to-context candidate selection
  evaluation/checks.json        repository verification configuration
  evaluation/eval.sh            verification runner
  evaluation/harness_lint.dart  structural and documentation invariant checks
  evolution/rules.json          reviewed failure-handling knowledge
  evolution/failure_log.jsonl   raw verification failure records
```

Human-facing rules live in the root `AGENTS.md` and `docs/agent/`. Keep automation generic; project-specific facts belong in maps and configuration.

For isolated tests or CI integration, `AGENT_CHECKS_FILE`, `AGENT_LOG_DIR`, and `AGENT_FAILURE_LOG` can override the runner's default paths.
