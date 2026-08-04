process CLUSTERING_SQUIDPY_PREPARE {
    tag "${pair_id}:${segmentation}"

    input:
    tuple val(pair_id),
        val(segmentation),
        val(samples_json)

    output:
    tuple val(pair_id),
        val(segmentation),
        val(samples_json),
        path("clustering_squidpy_config.json"),
        path("clustering_prepare_out")

    script:
    """
    set -euo pipefail
    echo '{"stub": "${pair_id} ${segmentation} clustering config"}' > clustering_squidpy_config.json
    mkdir -p clustering_prepare_out
    echo "stub prepared clustering input" > clustering_prepare_out/prepared.txt
    """
}

process CLUSTERING_SQUIDPY_COMPUTE {
    tag "${pair_id}:${segmentation}"

    input:
    tuple val(pair_id),
        val(segmentation),
        val(samples_json),
        path(clustering_config),
        path(prepared_dir)

    output:
    tuple val(pair_id),
        val(segmentation),
        val(samples_json),
        path("clustering_compute_out")

    script:
    """
    set -euo pipefail
    mkdir -p clustering_compute_out
    echo "stub computed clustering" > clustering_compute_out/computed.txt
    """
}

process CLUSTERING_SQUIDPY_FINALIZE {
    tag "${pair_id}:${segmentation}"

    publishDir { "${params.outdir}/${pair_id}/${segmentation}/clustering_squidpy" }, mode: "copy", overwrite: true

    input:
    tuple val(pair_id),
        val(segmentation),
        val(samples_json),
        path(computed_dir)

    output:
    tuple val(pair_id),
        val(segmentation),
        val(samples_json),
        path("clustering_squidpy_out")

    script:
    """
    set -euo pipefail
    mkdir -p clustering_squidpy_out
    echo "stub clustered outputs for ${pair_id} ${segmentation}" > clustering_squidpy_out/clustering_manifest.txt
    """
}
