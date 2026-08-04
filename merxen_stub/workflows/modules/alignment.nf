process ALIGN {
    tag "${pair_id}"

    publishDir { "${params.outdir}/${pair_id}/alignment" }, mode: "copy", overwrite: true

    input:
    tuple val(pair_id),
        val(merscope_zarr_path),
        val(xenium_zarr_path)

    output:
    tuple val(pair_id),
        val(merscope_zarr_path),
        val(xenium_zarr_path),
        path("align_out/alignment_transform.json"),
        path("align_out/alignment_coords")

    script:
    """
    set -euo pipefail
    mkdir -p align_out/alignment_coords
    echo '{"stub": "${pair_id} alignment transform"}' > align_out/alignment_transform.json
    echo "x,y" > align_out/alignment_coords/${pair_id}_raw_centroids.csv
    """
}

process ALIGN_QC {
    tag "${pair_id}"

    publishDir { "${params.outdir}/${pair_id}/alignment_qc" }, mode: "copy", overwrite: true

    input:
    tuple val(pair_id),
        val(merscope_zarr),
        val(xenium_zarr),
        path(transform_json),
        path(coords_dir)

    output:
    tuple val(pair_id), path("alignment_qc_out")

    script:
    """
    set -euo pipefail
    mkdir -p alignment_qc_out
    echo '{"stub": "${pair_id} alignment qc"}' > alignment_qc_out/${pair_id}_alignment_qc.json
    """
}
