process BUILD_SPATIALDATA {
    tag "${pair_id}:${platform}"

    publishDir { "${params.outdir}/${pair_id}/${platform.toLowerCase()}/spatialdata" }, mode: "symlink", overwrite: true

    input:
    tuple val(key), val(pair_id), val(platform), val(build_config_json)

    output:
    tuple val(key), val(pair_id), val(platform), path("spatialdata_out/source_spatialdata.zarr")

    script:
    """
    set -euo pipefail

    cat > build_config.json <<'JSON'
${build_config_json}
JSON

    # Mimic merxen build-spatialdata input resolution (io/builders/pipeline.py):
    # input_path must exist and be an accessible directory — either a raw export
    # folder or a reusable .zarr cache — otherwise the real stage raises
    # FileNotFoundError. On Flow this is what fails if the selected data path is
    # not mounted into the process container, so the stub checks it too.
    input_path=\$(grep '"input_path"' build_config.json | head -1 | sed -E 's/.*"input_path": *"(.*)".*/\\1/')

    if [ -z "\${input_path}" ]; then
        echo "ERROR: no input_path in build config for ${pair_id}:${platform}" >&2
        exit 1
    fi
    if [ ! -e "\${input_path}" ]; then
        echo "ERROR: ${platform} input_path is not accessible from this process: \${input_path}" >&2
        echo "       (on Flow this usually means the data path is not mounted into the container)" >&2
        exit 1
    fi
    if [ ! -d "\${input_path}" ]; then
        echo "ERROR: ${platform} input_path exists but is not a directory: \${input_path}" >&2
        exit 1
    fi

    echo "[stub] ${platform} input_path=\${input_path}; contents:" >&2
    ls -A "\${input_path}" >&2

    # A reusable SpatialData cache is just a .zarr directory; a raw export folder
    # must contain the platform-specific files the builder reads.
    case "\${input_path}" in
        *.zarr)
            : ;;
        *)
            missing=""
            if [ "${platform}" = "MERSCOPE" ]; then
                for req in images micron_to_mosaic_pixel_transform.csv cell_boundaries.parquet; do
                    [ -e "\${input_path}/\${req}" ] || missing="\${missing} \${req}"
                done
                if [ ! -e "\${input_path}/detected_transcripts.parquet" ] && [ ! -e "\${input_path}/detected_transcripts.csv" ]; then
                    missing="\${missing} detected_transcripts.parquet|csv"
                fi
            elif [ "${platform}" = "XENIUM" ]; then
                if [ ! -e "\${input_path}/experiment.xenium" ] && [ ! -e "\${input_path}/specs.json" ] && [ ! -e "\${input_path}/specs/specs.json" ]; then
                    missing="\${missing} experiment.xenium|specs.json"
                fi
                [ -e "\${input_path}/transcripts.parquet" ] || missing="\${missing} transcripts.parquet"
            fi
            if [ -n "\${missing}" ]; then
                echo "ERROR: ${platform} raw input \${input_path} is missing expected entries:\${missing}" >&2
                exit 1
            fi
            ;;
    esac

    mkdir -p spatialdata_out/source_spatialdata.zarr
    echo '{"stub": "${pair_id}_${platform} source spatialdata"}' > spatialdata_out/source_spatialdata.zarr/.zattrs
    """
}
