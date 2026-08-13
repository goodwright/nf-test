process MECR_REFERENCE {
    tag "WHB-10Xv3"

    publishDir { "${params.outdir}/mecr_reference" }, mode: "copy", overwrite: true

    input:
    tuple val(samples_json), path(reference_files, stageAs: "mecr_refs/*")

    output:
    path("mecr_reference_out")

    script:
    """
    set -euo pipefail
    staged=0
    for ref in mecr_refs/*; do
        if [ "\$ref" = "mecr_refs/*" ]; then break; fi
        if [ ! -e "\$ref" ]; then
            echo "ERROR: MECR reference not accessible from this process: \$ref" >&2
            exit 1
        fi
        staged=\$((staged + 1))
    done
    if [ "\$staged" -eq 0 ]; then
        echo "ERROR: no MECR reference files were staged" >&2
        exit 1
    fi
    echo "[stub] \$staged MECR reference files staged and accessible" >&2
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
