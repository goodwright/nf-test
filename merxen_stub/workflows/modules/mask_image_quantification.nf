process MASK_IMAGE_QUANTIFICATION {
    tag "${pair_id}:${platform}"

    publishDir { "${params.outdir}/${pair_id}/${platform.toLowerCase()}/mask_image_quantification" }, mode: "symlink", overwrite: true

    input:
    tuple val(key),
        val(pair_id),
        val(platform),
        val(mask_image_quantification_config_json),
        path(latest_zarr),
        path(mask_path)

    output:
    tuple val(key),
        val(pair_id),
        val(platform),
        path("latest_input.zarr"),
        path("mask_image_quantification_out")

    script:
    """
    set -euo pipefail
    if [[ ! -e latest_input.zarr ]]; then
        ln -s ${latest_zarr} latest_input.zarr
    fi
    mkdir -p mask_image_quantification_out
    echo "stub mask image quantification for ${pair_id}_${platform}" > mask_image_quantification_out/${pair_id}_${platform}_mask_image_quantification_summary.json
    """
}
