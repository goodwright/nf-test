process DISTANCE_FROM_OBJECT_ANNOTATE {
    tag "${pair_id}:${platform}"

    publishDir { "${params.outdir}/${pair_id}/${platform.toLowerCase()}/distance_from_object" }, mode: "symlink", overwrite: true

    input:
    tuple val(key),
        val(pair_id),
        val(platform),
        val(distance_segmentations),
        val(distance_config_json),
        path(latest_zarr),
        path(object_annotations)

    output:
    tuple val(key),
        val(pair_id),
        val(platform),
        val(distance_segmentations),
        path("latest_input.zarr"),
        path("distance_from_object_out")

    script:
    """
    set -euo pipefail
    if [[ ! -e latest_input.zarr ]]; then
        ln -s ${latest_zarr} latest_input.zarr
    fi
    mkdir -p distance_from_object_out
    echo '{"stub": "${pair_id} ${platform} distance from object summary"}' > distance_from_object_out/distance_from_object_summary.json
    echo '{"stub": "registered object annotations"}' > distance_from_object_out/registered_object_annotations.geojson
    """
}


process DISTANCE_FROM_OBJECT_COHORT {
    tag "${platform}"

    publishDir { "${params.outdir}/distance_from_object/cohort/${platform.toLowerCase()}" }, mode: "symlink", overwrite: true

    input:
    tuple val(platform),
        val(cohort_config_json),
        path(annotation_output_dirs, stageAs: "pair_outputs/dir??/*")

    output:
    tuple val(platform), path("distance_from_object_cohort_out")

    script:
    """
    set -euo pipefail
    mkdir -p distance_from_object_cohort_out
    echo '{"stub": "${platform} distance from object cohort summary"}' > distance_from_object_cohort_out/distance_from_object_cohort_summary.json
    """
}
