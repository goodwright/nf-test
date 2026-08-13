process MAPMYCELLS {
    tag "${pair_id}:${segmentation}"

    publishDir { "${params.outdir}/${pair_id}/${segmentation}/mapmycells" }, mode: "copy", overwrite: true

    input:
    tuple val(pair_id),
        val(segmentation),
        val(samples_json),
        path(clustering_out_dir, stageAs: "clustering_squidpy_input"),
        path(reference_files, stageAs: "mapmycells_refs/*")

    output:
    tuple val(pair_id), val(segmentation), path("mapmycells_out")

    script:
    """
    set -euo pipefail
    for ref in mapmycells_refs/*; do
        if [ "\$ref" = "mapmycells_refs/*" ]; then break; fi
        if [ ! -e "\$ref" ]; then
            echo "ERROR: MapMyCells reference not accessible from this process: \$ref" >&2
            exit 1
        fi
    done
    mkdir -p mapmycells_out
    echo '{"stub": "${pair_id} ${segmentation} mapmycells manifest"}' > mapmycells_out/${pair_id}_mapmycells_manifest.json
    """
}
