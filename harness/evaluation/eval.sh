#!/usr/bin/env bash
# harness/evaluation/eval.sh
#
# 用法：bash harness/evaluation/eval.sh <package_layer> <package_name>
# 示例：bash harness/evaluation/eval.sh core core_ble
#        bash harness/evaluation/eval.sh feature feature_device_search
#
# 涉及原生 plugin 包时额外传 --native：
# bash harness/evaluation/eval.sh core core_ble --native

set -euo pipefail

LAYER=${1:?"Usage: eval.sh <layer> <package_name> [--native]"}
PKG=${2:?"Usage: eval.sh <layer> <package_name> [--native]"}
NATIVE=${3:-""}

PKG_PATH="packages/${LAYER}/${PKG}"
LOG_DIR="harness/logs/runs"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="${LOG_DIR}/${PKG}_${TIMESTAMP}.log"

mkdir -p "$LOG_DIR"

echo "=== Eval Gate: ${PKG} ===" | tee "$LOG_FILE"
echo "Timestamp: $TIMESTAMP" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

PASS=0
FAIL=0
FAIL_TYPES=()

# Gate 1: dart analyze
echo "--- [1/3] dart analyze ---" | tee -a "$LOG_FILE"
if dart analyze "$PKG_PATH" >> "$LOG_FILE" 2>&1; then
  echo "✓ analyze PASS" | tee -a "$LOG_FILE"
  ((PASS++))
else
  echo "✗ analyze FAIL" | tee -a "$LOG_FILE"
  ((FAIL++))
  FAIL_TYPES+=("AnalyzeError")
fi

# Gate 2: flutter test
echo "" | tee -a "$LOG_FILE"
echo "--- [2/3] flutter test ---" | tee -a "$LOG_FILE"
if flutter test "$PKG_PATH" >> "$LOG_FILE" 2>&1; then
  echo "✓ test PASS" | tee -a "$LOG_FILE"
  ((PASS++))
else
  echo "✗ test FAIL" | tee -a "$LOG_FILE"
  ((FAIL++))
  FAIL_TYPES+=("TestError")
fi

# Gate 3 (optional): native build check
if [ "$NATIVE" = "--native" ]; then
  EXAMPLE_PATH="${PKG_PATH}/example"
  if [ -d "$EXAMPLE_PATH" ]; then
    echo "" | tee -a "$LOG_FILE"
    echo "--- [3/3] native build (Android) ---" | tee -a "$LOG_FILE"
    if (cd "$EXAMPLE_PATH" && flutter build apk --debug) >> "$LOG_FILE" 2>&1; then
      echo "✓ android build PASS" | tee -a "$LOG_FILE"
      ((PASS++))
    else
      echo "✗ android build FAIL" | tee -a "$LOG_FILE"
      ((FAIL++))
      FAIL_TYPES+=("AndroidBuildError")
    fi
  else
    echo "--- [3/3] skipped (no example/ dir) ---" | tee -a "$LOG_FILE"
  fi
fi

echo "" | tee -a "$LOG_FILE"
echo "=== Result: ${PASS} PASS / ${FAIL} FAIL ===" | tee -a "$LOG_FILE"

# 失败时记录到 failure_log.jsonl
if [ "$FAIL" -gt 0 ]; then
  FAIL_TYPES_JSON=$(printf '%s\n' "${FAIL_TYPES[@]}" | jq -R . | jq -s .)
  LOG_ENTRY=$(jq -n \
    --arg ts "$TIMESTAMP" \
    --arg pkg "$PKG" \
    --arg layer "$LAYER" \
    --argjson types "$FAIL_TYPES_JSON" \
    --arg log "$LOG_FILE" \
    '{timestamp: $ts, package: $pkg, layer: $layer, fail_types: $types, log: $log, resolved: false}')

  echo "$LOG_ENTRY" >> harness/evolution/failure_log.jsonl
  echo "Failure logged → harness/evolution/failure_log.jsonl" | tee -a "$LOG_FILE"

  # 查已知修复规则
  echo "" | tee -a "$LOG_FILE"
  echo "--- Known fixes (from rules.json) ---" | tee -a "$LOG_FILE"
  for TYPE in "${FAIL_TYPES[@]}"; do
    FIX=$(jq -r --arg t "$TYPE" '.[$t] // empty | "[\($t)] " + (.fix | join(" → "))' \
      harness/evolution/rules.json 2>/dev/null || echo "")
    if [ -n "$FIX" ]; then
      echo "  $FIX" | tee -a "$LOG_FILE"
    else
      echo "  [$TYPE] 无已知修复规则 → 需人工处理" | tee -a "$LOG_FILE"
    fi
  done

  exit 1
fi

exit 0
