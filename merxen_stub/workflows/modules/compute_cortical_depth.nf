process COMPUTE_CORTICAL_DEPTH {
    tag "${pair_id}:${platform}"

    publishDir { "${params.outdir}/${pair_id}/${platform.toLowerCase()}/compute_cortical_depth" }, mode: "symlink", overwrite: true

    input:
    tuple val(key),
        val(pair_id),
        val(platform),
        val(cortical_depth_config_json),
        path(latest_zarr),
        path(annotation_files, stageAs: "annotations/*")

    output:
    tuple val(key),
        val(pair_id),
        val(platform),
        path("latest_input.zarr"),
        path("compute_cortical_depth_out")

    script:
    """
    set -euo pipefail
    staged=0
    for annotation in annotations/*; do
        if [ "\$annotation" = "annotations/*" ]; then break; fi
        if [ ! -e "\$annotation" ]; then
            echo "ERROR: cortical-depth annotation not accessible from this process: \$annotation" >&2
            exit 1
        fi
        staged=\$((staged + 1))
    done
    if [ "\$staged" -eq 0 ]; then
        echo "ERROR: no cortical-depth annotation GeoJSONs were staged for ${pair_id}:${platform}" >&2
        exit 1
    fi
    if [[ ! -e latest_input.zarr ]]; then
        ln -s ${latest_zarr} latest_input.zarr
    fi
    mkdir -p compute_cortical_depth_out
    echo '{"stub": "${pair_id} ${platform} cortical depth qc summary"}' > compute_cortical_depth_out/cortical_depth_qc_summary.json
    """
}
