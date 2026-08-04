process COMPUTE_CORTICAL_DEPTH {
    tag "${pair_id}:${platform}"

    publishDir { "${params.outdir}/${pair_id}/${platform.toLowerCase()}/compute_cortical_depth" }, mode: "symlink", overwrite: true

    input:
    tuple val(key),
        val(pair_id),
        val(platform),
        val(cortical_depth_config_json),
        path(latest_zarr)

    output:
    tuple val(key),
        val(pair_id),
        val(platform),
        path("latest_input.zarr"),
        path("compute_cortical_depth_out")

    script:
    """
    set -euo pipefail
    if [[ ! -e latest_input.zarr ]]; then
        ln -s ${latest_zarr} latest_input.zarr
    fi
    mkdir -p compute_cortical_depth_out
    echo '{"stub": "${pair_id} ${platform} cortical depth qc summary"}' > compute_cortical_depth_out/cortical_depth_qc_summary.json
    """
}
