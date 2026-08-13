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
    cat > enrich_config.json <<'JSON'
${enrich_config_json}
JSON

    # Side-channel update: the real stage mutates the durable latest zarr in
    # place at an absolute path under outdir, written earlier by segmentation
    # outside publishDir. Require it and update it so environments where that
    # write did not survive (e.g. it landed inside a discarded task container)
    # fail here like the real pipeline.
    persistent_zarr=\$(grep '"persistent_output_path"' enrich_config.json | head -1 | sed -E 's/.*": *"([^"]*)".*/\\1/')
    if [ -z "\$persistent_zarr" ]; then
        echo "ERROR: no persistent_output_path in enrich config for ${pair_id}:${platform}" >&2
        exit 1
    fi
    if [ ! -d "\$persistent_zarr" ]; then
        echo "ERROR: persistent latest zarr missing: \$persistent_zarr" >&2
        echo "       (the segmentation side-channel write did not survive — expected when tasks cannot reach outdir, or when a container discarded the write)" >&2
        exit 1
    fi
    echo "enrich updated ${pair_id}_${platform}" >> "\$persistent_zarr/provenance.txt"

    ln -s ${latest_zarr} latest_input.zarr
    mkdir -p enrich_out
    echo "shape,transcripts_assigned" > enrich_out/${pair_id}_${platform}_assignment_summary.csv
    """
}
