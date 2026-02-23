params.flag_a = false
params.flag_b = false
params.flag_c = false

process print_params {
    publishDir "${projectDir}/results"

    output:
    path("params.txt")

    script:
    """
    echo "flag_a: ${params.flag_a}" > params.txt
    echo "flag_b: ${params.flag_b}" >> params.txt
    echo "flag_c: ${params.flag_c}" >> params.txt
    """
}

workflow {
    print_params()
}
