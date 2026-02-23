#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
RESULTS_DIR="$PROJECT_DIR/results"
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

echo "=== Test: All params true ==="
cleanup

if nextflow run "$PROJECT_DIR/main.nf" --flag_a true --flag_b true --flag_c true -w "$PROJECT_DIR/work" 2>/dev/null; then
    if [ -f "$RESULTS_DIR/params.txt" ]; then
        report "PASS" "params.txt exists"
    else
        report "FAIL" "params.txt exists"
    fi

    if grep -q "flag_a: true" "$RESULTS_DIR/params.txt"; then
        report "PASS" "flag_a is true"
    else
        report "FAIL" "flag_a is true"
    fi

    if grep -q "flag_b: true" "$RESULTS_DIR/params.txt"; then
        report "PASS" "flag_b is true"
    else
        report "FAIL" "flag_b is true"
    fi

    if grep -q "flag_c: true" "$RESULTS_DIR/params.txt"; then
        report "PASS" "flag_c is true"
    else
        report "FAIL" "flag_c is true"
    fi
else
    report "FAIL" "Pipeline completed successfully with all true"
fi

echo ""
echo "=== Test: Mixed params ==="
cleanup

if nextflow run "$PROJECT_DIR/main.nf" --flag_a true --flag_b false --flag_c true -w "$PROJECT_DIR/work" 2>/dev/null; then
    if grep -q "flag_a: true" "$RESULTS_DIR/params.txt"; then
        report "PASS" "flag_a is true"
    else
        report "FAIL" "flag_a is true"
    fi

    if grep -q "flag_b: false" "$RESULTS_DIR/params.txt"; then
        report "PASS" "flag_b is false"
    else
        report "FAIL" "flag_b is false"
    fi

    if grep -q "flag_c: true" "$RESULTS_DIR/params.txt"; then
        report "PASS" "flag_c is true"
    else
        report "FAIL" "flag_c is true"
    fi
else
    report "FAIL" "Pipeline completed successfully with mixed params"
fi

echo ""
echo "=== Test: All params false ==="
cleanup

if nextflow run "$PROJECT_DIR/main.nf" --flag_a false --flag_b false --flag_c false -w "$PROJECT_DIR/work" 2>/dev/null; then
    if grep -q "flag_a: false" "$RESULTS_DIR/params.txt"; then
        report "PASS" "flag_a is false"
    else
        report "FAIL" "flag_a is false"
    fi

    if grep -q "flag_b: false" "$RESULTS_DIR/params.txt"; then
        report "PASS" "flag_b is false"
    else
        report "FAIL" "flag_b is false"
    fi

    if grep -q "flag_c: false" "$RESULTS_DIR/params.txt"; then
        report "PASS" "flag_c is false"
    else
        report "FAIL" "flag_c is false"
    fi
else
    report "FAIL" "Pipeline completed successfully with all false"
fi

cleanup

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ]
