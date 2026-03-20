params.input = null

process PROCESS_SAMPLE {
    input:
    tuple val(name), path(input_file)

    output:
    tuple val(name), path("${name}_processed.txt")

    script:
    """
    wc -c < ${input_file} | tr -d ' ' > ${name}_processed.txt
    """
}

process SUMMARIZE_SAMPLE {
    input:
    tuple val(name), path(processed)

    output:
    path "${name}_summary.txt"

    script:
    """
    echo "Sample: ${name}" > ${name}_summary.txt
    echo "Characters: \$(cat ${processed})" >> ${name}_summary.txt
    """
}

workflow {
    Channel
        .fromPath(params.input)
        .splitCsv(header: true)
        .map { row -> tuple(row.name, file(row.file_path)) }
        .set { csv_ch }

    processed = PROCESS_SAMPLE(csv_ch)
    SUMMARIZE_SAMPLE(processed)
}
