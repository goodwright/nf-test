process VISUALIZE {
    tag "${pair_id}:${segmentation}"

    publishDir { "${params.outdir}/${pair_id}/${segmentation}/visualization" }, mode: "copy", overwrite: true

    input:
    tuple val(pair_id),
        val(segmentation),
        val(samples_json)

    output:
    tuple val(pair_id), val(segmentation), path("visualize_out")

    script:
    """
    set -euo pipefail
    mkdir -p visualize_out
    echo "stub visualization for ${pair_id} ${segmentation}" > visualize_out/${pair_id}_visualization.txt
    """
}
