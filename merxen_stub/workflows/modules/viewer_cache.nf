process VIEWER_CACHE {
    tag "${pair_id}:${platform}"

    publishDir { "${params.outdir}/${pair_id}/${platform.toLowerCase()}/viewer_cache" }, mode: "symlink", overwrite: true

    input:
    tuple val(key), val(pair_id), val(platform), val(viewer_cache_config_json), path(latest_zarr)

    output:
    tuple val(key), val(pair_id), val(platform), path("latest_input.zarr"), path("viewer_cache_out")

    script:
    """
    set -euo pipefail
    if [[ ! -e latest_input.zarr ]]; then
        ln -s ${latest_zarr} latest_input.zarr
    fi
    mkdir -p viewer_cache_out
    echo "stub viewer cache for ${pair_id}_${platform}" > viewer_cache_out/viewer_cache_manifest.json
    """
}
