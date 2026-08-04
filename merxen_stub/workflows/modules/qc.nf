process VALIDATE_ANALYSIS_LAYER {
    tag "${pair_id}:${platform}:${segmentation}"

    input:
    tuple val(key),
        val(pair_id),
        val(platform),
        val(segmentation),
        path(latest_zarr),
        val(table_key),
        val(shape_key),
        val(settings)

    output:
    tuple val(key),
        val(pair_id),
        val(platform),
        val(segmentation),
        path(latest_zarr),
        val(table_key),
        val(shape_key),
        val(settings),
        path("analysis_layer_validation.json")

    script:
    """
    set -euo pipefail
    echo '{"stub": "${pair_id}_${platform} ${segmentation} analysis layer valid"}' > analysis_layer_validation.json
    """
}


process QC {
    tag "${pair_id}:${platform}:${segmentation}"

    publishDir { "${params.outdir}/${pair_id}/${platform.toLowerCase()}/${segmentation}/qc" }, mode: "symlink", overwrite: true

    input:
    tuple val(key),
        val(pair_id),
        val(platform),
        val(segmentation),
        path(latest_zarr),
        val(table_key),
        val(shape_key)

    output:
    tuple val(key),
        val(pair_id),
        val(platform),
        val(segmentation),
        path(latest_zarr),
        path("qc_out"),
        val(table_key),
        val(shape_key)

    script:
    """
    set -euo pipefail
    mkdir -p qc_out
    dataset=\$(echo "${pair_id}_${platform}" | tr '[:upper:]' '[:lower:]')
    echo "metric,value" > qc_out/\${dataset}_qc_summary.csv
    """
}
