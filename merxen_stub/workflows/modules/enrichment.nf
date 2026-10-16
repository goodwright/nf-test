process ENRICH {
    tag "${pair_id}:${platform}"

    publishDir { "${params.outdir}/${pair_id}/${platform.toLowerCase()}/enrichment" }, mode: "symlink", overwrite: true

    input:
    tuple val(key), val(pair_id), val(platform), val(enrich_config_json), path(latest_zarr), path(mask_path), path(nuclei_mask_path)

    output:
    tuple val(key), val(pair_id), val(platform), path("latest_input.zarr"), path("enrich_out")

    script:
    """
    set -euo pipefail
    ln -s ${latest_zarr} latest_input.zarr
    mkdir -p enrich_out
    echo "shape,transcripts_assigned" > enrich_out/${pair_id}_${platform}_assignment_summary.csv
    """
}
