#!/usr/bin/env bash
#
# Local smoke test for the stubbed MerXen pipeline.
#
# Runs the pipeline in two configurations and asserts that the expected
# directory-typed outputs appear. Verifies the DAG wiring and the output tree,
# not any scientific result (every process body is stubbed).
set -euo pipefail

# MerXen's main.nf is large; it only compiles on Nextflow's newer language
# parser (>= 26.x). Older versions fail with "String too long".
export NXF_VER="${NXF_VER:-26.04.6}"

TEST_DIR="$(cd "$(dirname "$0")" && pwd)"
STUB_DIR="$(cd "$TEST_DIR/.." && pwd)"
MAIN_NF="$STUB_DIR/workflows/main.nf"
LOCAL_CONFIG="$TEST_DIR/local.config"
REFS="$TEST_DIR/refs"
INPUTS="$TEST_DIR/inputs"
WORK="$TEST_DIR/work"

PASS=0
FAIL=0

report() {
    if [ "$1" = "PASS" ]; then echo "  PASS: $2"; PASS=$((PASS + 1))
    else echo "  FAIL: $2"; FAIL=$((FAIL + 1)); fi
}

assert_dir() {
    [ -d "$1" ] && report "PASS" "$2" || report "FAIL" "$2 (missing $1)"
}

# Reference paths that MerXen hardcodes; on Flow these become data inputs.
ref_args=(
    --mecr_neurons_h5ad_path="$REFS/whb_neurons.h5ad"
    --mecr_nonneurons_h5ad_path="$REFS/whb_nonneurons.h5ad"
    --mecr_cell_metadata_path="$REFS/whb_cell_metadata.csv"
    --mecr_taxonomy_metadata_path="$REFS/whb_taxonomy.csv"
    --mecr_cluster_membership_path="$REFS/whb_cluster_membership.csv"
    --clustering_squidpy_broad_marker_lookup_path="$REFS/query_markers.json"
    --clustering_squidpy_broad_taxonomy_metadata_path="$REFS/whb_taxonomy.csv"
    --clustering_squidpy_broad_cluster_membership_path="$REFS/whb_cluster_membership.csv"
    --mapmycells_marker_lookup_path="$REFS/query_markers.json"
    --mapmycells_precomputed_stats_path="$REFS/precomputed_stats.h5"
)

run_pipeline() {
    local outdir="$1"; shift
    local samplesheet="$1"; shift
    rm -rf "$outdir" "$WORK"
    nextflow -log "$TEST_DIR/.nextflow.log" run "$MAIN_NF" \
        -c "$LOCAL_CONFIG" \
        -work-dir "$WORK" \
        --samplesheet "$samplesheet" \
        --outdir "$outdir" \
        "${ref_args[@]}" \
        "$@"
}

# ---------------------------------------------------------------------------
echo "=== Test A: paired defaults (build -> clustering_squidpy) ==="
SS_A="$TEST_DIR/.samplesheet_a.csv"
{
    echo "pair_id,merscope_dir,xenium_dir"
    echo "EX01,$INPUTS/merscope/EX01,$INPUTS/xenium/EX01"
} > "$SS_A"
OUT_A="$TEST_DIR/results_a"
if run_pipeline "$OUT_A" "$SS_A" --spatial_gene_analysis_transcript_analysis_enabled false; then
    assert_dir "$OUT_A/EX01/merscope/spatialdata/spatialdata_out/source_spatialdata.zarr" "MERSCOPE source spatialdata zarr"
    assert_dir "$OUT_A/EX01/xenium/spatialdata/spatialdata_out/source_spatialdata.zarr"   "XENIUM source spatialdata zarr"
    assert_dir "$OUT_A/EX01/merscope/enrichment/enrich_out"                               "MERSCOPE enrich_out dir"
    assert_dir "$OUT_A/EX01/merscope/viewer_cache/viewer_cache_out"                       "MERSCOPE viewer_cache_out dir"
    assert_dir "$OUT_A/EX01/merscope/mask_image_quantification/mask_image_quantification_out" "MERSCOPE mask_image_quantification_out dir"
    assert_dir "$OUT_A/EX01/merscope/segmentation/segment_out/proseg_base_latest.zarr"    "MERSCOPE proseg base latest zarr"
    assert_dir "$OUT_A/EX01/merscope/reseg/qc/qc_out"                                     "MERSCOPE reseg qc_out dir"
    assert_dir "$OUT_A/EX01/xenium/reseg/qc/qc_out"                                       "XENIUM reseg qc_out dir"
    assert_dir "$OUT_A/mecr_reference/mecr_reference_out"                                 "shared MECR reference dir"
    assert_dir "$OUT_A/EX01/reseg/mecr/mecr_out"                                          "reseg mecr_out dir"
    assert_dir "$OUT_A/EX01/reseg/comparison/compare_out"                                 "reseg compare_out dir (paired)"
    assert_dir "$OUT_A/EX01/reseg/visualization/visualize_out"                            "reseg visualize_out dir"
    assert_dir "$OUT_A/EX01/reseg/spatial_gene_analysis/spatial_gene_analysis_out"        "reseg spatial_gene_analysis_out dir"
    assert_dir "$OUT_A/EX01/reseg/clustering_squidpy/clustering_squidpy_out"              "reseg clustering_squidpy_out dir"
    assert_dir "$OUT_A/EX01/xenium/enrichment/latest_input.zarr"                          "XENIUM enrichment latest_input.zarr (symlinked dir)"
else
    report "FAIL" "pipeline runs with paired defaults"
fi

# ---------------------------------------------------------------------------
echo ""
echo "=== Test B: paired, all opt-in stages (-> mapmycells) ==="
SS_B="$TEST_DIR/.samplesheet_b.csv"
{
    echo "pair_id,merscope_dir,xenium_dir,merscope_pial_boundary_geojson,merscope_side_boundaries_geojson,xenium_pial_boundary_geojson,xenium_side_boundaries_geojson,merscope_distance_object_annotation_geojson,xenium_distance_object_annotation_geojson"
    echo "EX01,$INPUTS/merscope/EX01,$INPUTS/xenium/EX01,$REFS/EX01_merscope_pia.geojson,$REFS/EX01_merscope_side.geojson,$REFS/EX01_xenium_pia.geojson,$REFS/EX01_xenium_side.geojson,$REFS/EX01_merscope_objects.geojson,$REFS/EX01_xenium_objects.geojson"
} > "$SS_B"
OUT_B="$TEST_DIR/results_b"
if run_pipeline "$OUT_B" "$SS_B" \
        --enable_alignment true \
        --cortical_depth_enabled true \
        --distance_from_object_enabled true \
        --stop_stage mapmycells; then
    assert_dir "$OUT_B/EX01/alignment/align_out/alignment_coords"                "alignment coords dir (paired)"
    assert_dir "$OUT_B/EX01/alignment_qc/alignment_qc_out"                       "alignment_qc_out dir"
    assert_dir "$OUT_B/EX01/merscope/compute_cortical_depth/compute_cortical_depth_out" "MERSCOPE compute_cortical_depth_out dir"
    assert_dir "$OUT_B/EX01/merscope/distance_from_object/distance_from_object_out"     "MERSCOPE distance_from_object_out dir"
    assert_dir "$OUT_B/distance_from_object/cohort/merscope/distance_from_object_cohort_out" "MERSCOPE distance cohort dir"
    assert_dir "$OUT_B/EX01/reseg/mapmycells/mapmycells_out"                     "reseg mapmycells_out dir"
else
    report "FAIL" "pipeline runs with all opt-in stages"
fi

rm -rf "$WORK"
echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ]
