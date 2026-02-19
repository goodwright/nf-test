params.input = null

process validate_and_wc {
    publishDir "results/wc"

    input:
    tuple val(name), path(input_file)

    output:
    path("${name}_wc.txt")

    script:
    """
    if [[ ! "${input_file}" == *.txt ]]; then
        echo "ERROR: ${input_file} is not a .txt file" >&2
        exit 1
    fi
    wc ${input_file} > ${name}_wc.txt
    """
}

workflow {
    Channel
        .fromPath(params.input)
        .splitCsv(header: true)
        .map { row -> tuple(row.name, file(row.file_path)) }
        .set { csv_ch }

    validate_and_wc(csv_ch)
}
