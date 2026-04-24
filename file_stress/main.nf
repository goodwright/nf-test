params.num_processes = 3
params.curated_outputs_per_process = 2
params.process_outputs_per_process = 3
params.scratch_files_per_process = 100
params.enable_aggregator = true
params.filename_padding_chars = 0

process GENERATE_FILES {
    input:
    val index

    output:
    path "curated_${index}_*.txt", emit: curated, optional: true
    path "process_${index}_*.txt", emit: process_out, optional: true

    // Padding inflates each declared-output filename so the absolute path
    // contributes more bytes to Flow's batch_file_metadata shell command.
    // Lets us cross ARG_MAX with far fewer process executions.
    script:
    """
    pad=""
    for ((j=1; j<=${params.filename_padding_chars}; j++)); do pad="\${pad}x"; done
    for ((i=1; i<=${params.curated_outputs_per_process}; i++)); do
        echo "curated file \${i} from process ${index}" > curated_${index}_\${i}_\${pad}.txt
    done
    for ((i=1; i<=${params.process_outputs_per_process}; i++)); do
        echo "process file \${i} from process ${index}" > process_${index}_\${i}_\${pad}.txt
    done
    for ((i=1; i<=${params.scratch_files_per_process}; i++)); do
        echo "scratch file \${i} from process ${index}" > scratch_${index}_\${i}.txt
    done
    """
}

process AGGREGATE {
    input:
    path curated_files

    output:
    path "aggregate_summary.txt"

    script:
    """
    count=\$(ls curated_*.txt 2>/dev/null | wc -l | tr -d ' ')
    echo "Aggregated \${count} curated files" > aggregate_summary.txt
    for f in curated_*.txt; do
        [ -e "\$f" ] && echo "- \$f" >> aggregate_summary.txt
    done
    """
}

workflow {
    indices = Channel.fromList((1..params.num_processes.toInteger()).toList())
    generated = GENERATE_FILES(indices)

    if (params.enable_aggregator) {
        AGGREGATE(generated.curated.flatten().collect())
    }
}
