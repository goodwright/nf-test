process ENSURE_PROSEG {
    tag "proseg"

    input:
    val trigger

    output:
    path("proseg_path.txt")

    script:
    """
    set -euo pipefail
    printf '%s\\n' /usr/bin/true > proseg_path.txt
    """
}
