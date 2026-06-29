#!/usr/bin/env bash

set -uo pipefail

MODE=${1:-quick}
CONFIG=${AGENT_CHECKS_FILE:-harness/evaluation/checks.json}
LOG_DIR=${AGENT_LOG_DIR:-harness/logs/runs}
FAILURE_LOG=${AGENT_FAILURE_LOG:-harness/evolution/failure_log.jsonl}

if [[ "$MODE" != "quick" && "$MODE" != "full" ]]; then
  echo "Usage: bash harness/evaluation/eval.sh [quick|full]" >&2
  exit 64
fi

for tool in jq bash; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "ERROR: required tool not found: $tool" >&2
    exit 69
  fi
done

if ! jq -e '.checks | type == "array"' "$CONFIG" >/dev/null 2>&1; then
  echo "ERROR: invalid checks configuration: $CONFIG" >&2
  exit 65
fi

mkdir -p "$LOG_DIR"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="$LOG_DIR/eval_${MODE}_${TIMESTAMP}.log"
mapfile_compat() {
  while IFS= read -r line; do
    CHECKS+=("$line")
  done
}

CHECKS=()
mapfile_compat < <(
  jq -r --arg mode "$MODE" '
    .checks[]
    | select((.modes // ["quick", "full"]) | index($mode))
    | [.id, .command] | @tsv
  ' "$CONFIG"
)

if [[ ${#CHECKS[@]} -eq 0 ]]; then
  echo "ERROR: no checks configured for mode: $MODE" >&2
  exit 65
fi

PASS=0
FAIL=0
FAILED_IDS=()

{
  echo "=== Agent Harness Evaluation ==="
  echo "Mode: $MODE"
  echo "Config: $CONFIG"
  echo
} | tee "$LOG_FILE"

for check in "${CHECKS[@]}"; do
  IFS=$'\t' read -r id command <<< "$check"
  echo "--- $id ---" | tee -a "$LOG_FILE"
  if bash -o pipefail -c "$command" >>"$LOG_FILE" 2>&1; then
    echo "PASS: $id" | tee -a "$LOG_FILE"
    PASS=$((PASS + 1))
  else
    status=$?
    echo "FAIL: $id (exit $status)" | tee -a "$LOG_FILE"
    FAIL=$((FAIL + 1))
    FAILED_IDS+=("$id")
  fi
  echo | tee -a "$LOG_FILE"
done

echo "Result: $PASS passed, $FAIL failed" | tee -a "$LOG_FILE"

if [[ $FAIL -gt 0 ]]; then
  failed_json=$(printf '%s\n' "${FAILED_IDS[@]}" | jq -R . | jq -s .)
  jq -cn \
    --arg timestamp "$TIMESTAMP" \
    --arg mode "$MODE" \
    --arg log "$LOG_FILE" \
    --argjson failed_checks "$failed_json" \
    '{timestamp: $timestamp, mode: $mode, failed_checks: $failed_checks, log: $log, resolved: false}' \
    >> "$FAILURE_LOG"
  exit 1
fi
