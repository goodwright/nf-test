params.input_file = null

process UPPERCASE {
    input:
    path input_file

    output:
    path "uppercased.txt"

    script:
    """
    tr '[:lower:]' '[:upper:]' < ${input_file} > uppercased.txt
    """
}

process LINE_COUNT {
    input:
    path input_file

    output:
    path "line_count.txt"

    script:
    """
    wc -l < ${input_file} | tr -d ' ' > line_count.txt
    """
}

process REPORT {
    input:
    path uppercased
    path line_count

    output:
    path "report"

    script:
    """
    mkdir report
    echo "Lines: \$(cat ${line_count})" > report/report.txt
    echo "Content:" >> report/report.txt
    cat ${uppercased} >> report/report.txt
    """
}

workflow {
    input_ch = Channel.fromPath(params.input_file)
    uppercased = UPPERCASE(input_ch)
    line_count = LINE_COUNT(uppercased)
    REPORT(uppercased, line_count)
}
