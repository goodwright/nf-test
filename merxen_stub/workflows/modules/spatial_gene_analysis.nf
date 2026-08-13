process SPATIAL_GENE_ANALYSIS {
    tag "${pair_id}:${segmentation}"

    publishDir { "${params.outdir}/${pair_id}/${segmentation}/spatial_gene_analysis" }, mode: "copy", overwrite: true

    input:
    tuple val(pair_id),
        val(segmentation),
        val(samples_json),
        val(transcript_analysis_enabled),
        path(annotation_files, stageAs: "annotations/*")

    output:
    tuple val(pair_id),
        val(segmentation),
        path("spatial_gene_analysis_out")

    script:
    """
    set -euo pipefail
    for annotation in annotations/*; do
        if [ "\$annotation" = "annotations/*" ]; then break; fi
        if [ ! -e "\$annotation" ]; then
            echo "ERROR: spatial-gene annotation not accessible from this process: \$annotation" >&2
            exit 1
        fi
    done
    mkdir -p spatial_gene_analysis_out
    echo '{"stub": "${pair_id} ${segmentation} spatial gene analysis", "transcript_analysis_enabled": ${transcript_analysis_enabled}}' > spatial_gene_analysis_out/${pair_id}_spatial_gene_analysis_manifest.json
    """
}
