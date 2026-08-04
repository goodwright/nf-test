process SPATIAL_GENE_ANALYSIS {
    tag "${pair_id}:${segmentation}"

    publishDir { "${params.outdir}/${pair_id}/${segmentation}/spatial_gene_analysis" }, mode: "copy", overwrite: true

    input:
    tuple val(pair_id),
        val(segmentation),
        val(samples_json),
        val(transcript_analysis_enabled)

    output:
    tuple val(pair_id),
        val(segmentation),
        path("spatial_gene_analysis_out")

    script:
    """
    set -euo pipefail
    mkdir -p spatial_gene_analysis_out
    echo '{"stub": "${pair_id} ${segmentation} spatial gene analysis", "transcript_analysis_enabled": ${transcript_analysis_enabled}}' > spatial_gene_analysis_out/${pair_id}_spatial_gene_analysis_manifest.json
    """
}
