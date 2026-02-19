#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
RESULTS_DIR="$PROJECT_DIR/results/wc"
PASS=0
FAIL=0

report() {
    local status=$1 description=$2
    if [ "$status" = "PASS" ]; then
        echo "  PASS: $description"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: $description"
        FAIL=$((FAIL + 1))
    fi
}

cleanup() {
    rm -rf "$RESULTS_DIR" "$PROJECT_DIR/work"
}

echo "=== Test: Valid CSV produces wc output files ==="
cleanup

if nextflow run "$PROJECT_DIR/wc_pipeline.nf" --input "$PROJECT_DIR/test_data/sample.csv" -w "$PROJECT_DIR/work" 2>/dev/null; then
    if [ -f "$RESULTS_DIR/hello_wc.txt" ]; then
        report "PASS" "hello_wc.txt exists"
    else
        report "FAIL" "hello_wc.txt exists"
    fi

    if [ -f "$RESULTS_DIR/world_wc.txt" ]; then
        report "PASS" "world_wc.txt exists"
    else
        report "FAIL" "world_wc.txt exists"
    fi

    if grep -q "2" "$RESULTS_DIR/hello_wc.txt"; then
        report "PASS" "hello_wc.txt contains line count"
    else
        report "FAIL" "hello_wc.txt contains line count"
    fi
else
    report "FAIL" "Pipeline completed successfully with valid CSV"
fi

echo ""
echo "=== Test: Invalid CSV (non-.txt file) causes pipeline failure ==="
cleanup

if nextflow run "$PROJECT_DIR/wc_pipeline.nf" --input "$PROJECT_DIR/test_data/invalid.csv" -w "$PROJECT_DIR/work" 2>/dev/null; then
    report "FAIL" "Pipeline fails for non-.txt file"
else
    report "PASS" "Pipeline fails for non-.txt file"
fi

cleanup

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ]
