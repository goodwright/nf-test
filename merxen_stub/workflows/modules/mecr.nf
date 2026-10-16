process MECR_REFERENCE {
    tag "WHB-10Xv3"

    publishDir { "${params.outdir}/mecr_reference" }, mode: "copy", overwrite: true

    input:
    val(samples_json)

    output:
    path("mecr_reference_out")

    script:
    """
    set -euo pipefail
    mkdir -p mecr_reference_out
    echo "gene,marker" > mecr_reference_out/mecr_reference_markers.csv
    echo '{"stub": "mecr reference manifest"}' > mecr_reference_out/mecr_reference_manifest.json
    """
}


process MECR {
    tag "${pair_id}:${segmentation}"

    publishDir { "${params.outdir}/${pair_id}/${segmentation}/mecr" }, mode: "copy", overwrite: true

    input:
    tuple val(pair_id),
        val(segmentation),
        val(samples_json),
        path(reference_out)

    output:
    tuple val(pair_id),
        val(segmentation),
        path("mecr_out")

    script:
    """
    set -euo pipefail
    mkdir -p mecr_out
    echo '{"stub": "${pair_id} ${segmentation} mecr summary"}' > mecr_out/${pair_id}_mecr_summary.csv
    """
}
