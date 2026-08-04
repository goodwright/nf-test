process BUILD_SPATIALDATA {
    tag "${pair_id}:${platform}"

    publishDir { "${params.outdir}/${pair_id}/${platform.toLowerCase()}/spatialdata" }, mode: "symlink", overwrite: true

    input:
    tuple val(key), val(pair_id), val(platform), val(build_config_json)

    output:
    tuple val(key), val(pair_id), val(platform), path("spatialdata_out/source_spatialdata.zarr")

    script:
    """
    set -euo pipefail
    mkdir -p spatialdata_out/source_spatialdata.zarr
    echo '{"stub": "${pair_id}_${platform} source spatialdata"}' > spatialdata_out/source_spatialdata.zarr/.zattrs
    """
}
