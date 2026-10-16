process MAPMYCELLS {
    tag "${pair_id}:${segmentation}"

    publishDir { "${params.outdir}/${pair_id}/${segmentation}/mapmycells" }, mode: "copy", overwrite: true

    input:
    tuple val(pair_id),
        val(segmentation),
        val(samples_json),
        path(clustering_out_dir, stageAs: "clustering_squidpy_input")

    output:
    tuple val(pair_id), val(segmentation), path("mapmycells_out")

    script:
    """
    set -euo pipefail
    mkdir -p mapmycells_out
    echo '{"stub": "${pair_id} ${segmentation} mapmycells manifest"}' > mapmycells_out/${pair_id}_mapmycells_manifest.json
    """
}
