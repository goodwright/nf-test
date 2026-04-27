#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORK_DIR="$PROJECT_DIR/work"
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
    rm -rf "$WORK_DIR"
}

count_in_work() {
    local pattern=$1
    find "$WORK_DIR" -type f -name "$pattern" 2>/dev/null | wc -l | tr -d ' '
}

echo "=== Test: Defaults (3 processes, aggregator on) ==="
cleanup
if nextflow run "$PROJECT_DIR/main.nf" -w "$WORK_DIR" 2>/dev/null; then
    [ "$(count_in_work 'curated_*.txt')" = "6" ]          && report "PASS" "6 curated files (3 × 2)"          || report "FAIL" "6 curated files (3 × 2)"
    [ "$(count_in_work 'process_*.txt')" = "9" ]          && report "PASS" "9 process outputs (3 × 3)"        || report "FAIL" "9 process outputs (3 × 3)"
    [ "$(count_in_work 'scratch_*.txt')" = "300" ]        && report "PASS" "300 scratch files (3 × 100)"      || report "FAIL" "300 scratch files (3 × 100)"
    [ "$(count_in_work 'aggregate_summary.txt')" = "1" ]  && report "PASS" "aggregate summary produced"       || report "FAIL" "aggregate summary produced"
else
    report "FAIL" "pipeline runs with defaults"
fi

echo ""
echo "=== Test: Scaled (10 processes, 5 curated, 2 process, 50 scratch) ==="
cleanup
if nextflow run "$PROJECT_DIR/main.nf" \
        --num_processes 10 \
        --curated_outputs_per_process 5 \
        --process_outputs_per_process 2 \
        --scratch_files_per_process 50 \
        -w "$WORK_DIR" 2>/dev/null; then
    [ "$(count_in_work 'curated_*.txt')" = "50" ]   && report "PASS" "50 curated files (10 × 5)"    || report "FAIL" "50 curated files (10 × 5)"
    [ "$(count_in_work 'process_*.txt')" = "20" ]   && report "PASS" "20 process outputs (10 × 2)"  || report "FAIL" "20 process outputs (10 × 2)"
    [ "$(count_in_work 'scratch_*.txt')" = "500" ]  && report "PASS" "500 scratch files (10 × 50)"  || report "FAIL" "500 scratch files (10 × 50)"
else
    report "FAIL" "pipeline runs with scaled config"
fi

echo ""
echo "=== Test: Aggregator disabled ==="
cleanup
if nextflow run "$PROJECT_DIR/main.nf" --enable_aggregator false -w "$WORK_DIR" 2>/dev/null; then
    [ "$(count_in_work 'curated_*.txt')" = "6" ]         && report "PASS" "curated files still produced"       || report "FAIL" "curated files still produced"
    [ "$(count_in_work 'aggregate_summary.txt')" = "0" ] && report "PASS" "no aggregate summary"               || report "FAIL" "no aggregate summary"
else
    report "FAIL" "pipeline runs with aggregator disabled"
fi

echo ""
echo "=== Test: Zero scratch files ==="
cleanup
if nextflow run "$PROJECT_DIR/main.nf" --scratch_files_per_process 0 -w "$WORK_DIR" 2>/dev/null; then
    [ "$(count_in_work 'scratch_*.txt')" = "0" ]  && report "PASS" "no scratch files"       || report "FAIL" "no scratch files"
    [ "$(count_in_work 'curated_*.txt')" = "6" ] && report "PASS" "curated files produced" || report "FAIL" "curated files produced"
else
    report "FAIL" "pipeline runs with zero scratch"
fi

echo ""
echo "=== Test: Filename padding inflates declared-output filenames ==="
cleanup
if nextflow run "$PROJECT_DIR/main.nf" --num_processes 2 --curated_outputs_per_process 1 --process_outputs_per_process 0 --scratch_files_per_process 0 --enable_aggregator false --filename_padding_chars 50 -w "$WORK_DIR" 2>/dev/null; then
    padded=$(find "$WORK_DIR" -type f -name 'curated_*xxxxxxxxxx*.txt' 2>/dev/null | wc -l | tr -d ' ')
    [ "$padded" = "2" ] && report "PASS" "2 padded curated filenames" || report "FAIL" "2 padded curated filenames (got $padded)"
else
    report "FAIL" "pipeline runs with padding"
fi

cleanup

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ]
