process COMPARE {
    tag "${pair_id}:${segmentation}"

    publishDir { "${params.outdir}/${pair_id}/${segmentation}/comparison" }, mode: "copy", overwrite: true

    input:
    tuple val(pair_id),
        val(segmentation),
        val(merscope_zarr),
        val(xenium_zarr),
        val(merscope_table_key),
        val(xenium_table_key)

    output:
    tuple val(pair_id), val(segmentation), path("compare_out")

    script:
    """
    set -euo pipefail
    mkdir -p compare_out
    echo '{"stub": "${pair_id} ${segmentation} comparison metrics"}' > compare_out/${pair_id}_comparison_metrics.json
    """
}
