process VISUALIZE {
    tag "${pair_id}:${segmentation}"

    publishDir { "${params.outdir}/${pair_id}/${segmentation}/visualization" }, mode: "copy", overwrite: true

    input:
    tuple val(pair_id),
        val(segmentation),
        val(samples_json)

    output:
    tuple val(pair_id), val(segmentation), path("visualize_out")

    script:
    """
    set -euo pipefail
    cat > samples.json <<'JSON'
${samples_json}
JSON

    # The real stage opens each sample's zarr at the absolute path embedded in
    # the samples JSON (a value, not a staged input). Verify those paths are
    # reachable from this process so an executor that does not expose the
    # Nextflow work tree fails here like the real pipeline would.
    grep -o '"zarr_path": *"[^"]*"' samples.json | sed -E 's/.*": *"(.*)"/\\1/' | while read -r zarr_path; do
        if [ ! -e "\$zarr_path" ]; then
            echo "ERROR: samples_json zarr_path not accessible from this process: \$zarr_path" >&2
            exit 1
        fi
    done

    mkdir -p visualize_out
    echo "stub visualization for ${pair_id} ${segmentation}" > visualize_out/${pair_id}_visualization.txt
    """
}
