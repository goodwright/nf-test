process CELLPOSE_SEGMENT {
    tag "${pair_id}:${platform}"

    publishDir { "${params.outdir}/${pair_id}/${platform.toLowerCase()}/segmentation" }, mode: "symlink", overwrite: true

    input:
    tuple val(key), val(pair_id), val(platform), val(seg_config_json)

    output:
    tuple val(key), val(pair_id), val(platform), val(seg_config_json), path("segment_out/cellpose_masks_tiled.npy"), path("segment_out/cellpose_cellprobs_tiled.npy"), path("segment_out/transcripts_for_proseg.csv"), path("segment_out/cellpose_transforms.json"), path("segment_out/cellpose_stitching_stats.json")

    script:
    """
    set -euo pipefail
    mkdir -p segment_out
    echo "stub cellpose mask for ${pair_id}_${platform}" > segment_out/cellpose_masks_tiled.npy
    echo "stub cellpose cellprobs for ${pair_id}_${platform}" > segment_out/cellpose_cellprobs_tiled.npy
    echo "cell_id,x,y" > segment_out/transcripts_for_proseg.csv
    echo '{"stub": "cellpose transforms"}' > segment_out/cellpose_transforms.json
    echo '{"stub": "cellpose stitching stats"}' > segment_out/cellpose_stitching_stats.json
    """
}


process CELLPOSE_NUCLEI_SEGMENT {
    tag "${pair_id}:${platform}:nuclei"

    publishDir { "${params.outdir}/${pair_id}/${platform.toLowerCase()}/segmentation" }, mode: "symlink", overwrite: true

    input:
    tuple val(key), val(pair_id), val(platform), val(seg_config_json)

    output:
    tuple val(key), val(pair_id), val(platform), val(seg_config_json), path("segment_out/cellpose_nuclei_masks_tiled.npy"), path("segment_out/cellpose_nuclei_stitching_stats.json")

    script:
    """
    set -euo pipefail
    mkdir -p segment_out
    echo "stub cellpose nuclei mask for ${pair_id}_${platform}" > segment_out/cellpose_nuclei_masks_tiled.npy
    echo '{"stub": "cellpose nuclei stitching stats"}' > segment_out/cellpose_nuclei_stitching_stats.json
    """
}


process PROSEG_SEGMENT {
    tag "${pair_id}:${platform}"

    publishDir { "${params.outdir}/${pair_id}/${platform.toLowerCase()}/segmentation" }, mode: "symlink", overwrite: true

    input:
    tuple val(key), val(pair_id), val(platform), val(seg_config_json), path(cellpose_mask), path(cellpose_cellprob), path(transcripts_csv), path(cellpose_transforms), path(_stitching_stats), path(nuclei_mask), path(_nuclei_stitching_stats), path(proseg_path_file)

    output:
    tuple val(key), val(pair_id), val(platform), path("segment_out/proseg_base_latest.zarr"), path(cellpose_mask), path(transcripts_csv), path(nuclei_mask)

    script:
    """
    set -euo pipefail
    mkdir -p segment_out/proseg_base_latest.zarr
    echo '{"stub": "${pair_id}_${platform} proseg base latest spatialdata"}' > segment_out/proseg_base_latest.zarr/.zattrs
    """
}


workflow SEGMENT {
    take:
    segment_inputs
    nuclei_results
    proseg_path

    main:
    cellpose_results = CELLPOSE_SEGMENT(segment_inputs)
    combined_cellpose_results = cellpose_results
        .join(nuclei_results)
        .map {
            key, pair_id, platform, seg_config_json, cellpose_mask,
            cellpose_cellprob, transcripts_csv, cellpose_transforms, stitching_stats,
            nuclei_pair_id, nuclei_platform, _nuclei_seg_config_json,
            nuclei_mask, nuclei_stitching_stats ->
            if (pair_id != nuclei_pair_id || platform != nuclei_platform) {
                error("Cell/nuclei Cellpose channel mismatch for ${key}")
            }
            tuple(
                key,
                pair_id,
                platform,
                seg_config_json,
                cellpose_mask,
                cellpose_cellprob,
                transcripts_csv,
                cellpose_transforms,
                stitching_stats,
                nuclei_mask,
                nuclei_stitching_stats,
            )
        }
    proseg_inputs = combined_cellpose_results
        .combine(proseg_path)
        .map {
            key, pair_id, platform, seg_config_json, cellpose_mask,
            cellpose_cellprob, transcripts_csv, cellpose_transforms, stitching_stats, nuclei_mask,
            nuclei_stitching_stats,
            proseg_path_file ->
            tuple(
                key,
                pair_id,
                platform,
                seg_config_json,
                cellpose_mask,
                cellpose_cellprob,
                transcripts_csv,
                cellpose_transforms,
                stitching_stats,
                nuclei_mask,
                nuclei_stitching_stats,
                proseg_path_file,
            )
        }
    segment_results = PROSEG_SEGMENT(proseg_inputs)

    emit:
    segment_results
}
