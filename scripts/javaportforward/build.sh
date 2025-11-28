#!/bin/bash

# Get contents of a existing bash function
# This function relies on a specific output format of
# `declare -f` and will probably not work on different shells or
# even bash versions (bash v5.0 and v5.1 were tested).
# It also relies on the function having a curly brace block body.
get-bash-function() {
    declare format="$1"; shift
    declare srcname="$1"; shift
    declare -f "$srcname" >/dev/null \
        || error 1 "No such function: $srcname" || return $?

    case "$format" in
        -b|body)
            # Body without function name declaration
            declare -f "$srcname" | tail --lines=+2
            ;;
        -c|body-content)
            # The content of the body without curly braces
            declare -f "$srcname" | tail --lines=+3 | head --lines=-1
            ;;
        -a|all)
            # The whole function, with name declaration
            declare -f "$srcname"
            ;;
        *)
            error 1 "Invalid format: $format" || return $?
        ;;
    esac
}

ship-bash-function-as() {
    declare srcname="$1"; shift
    declare destname="$1"; shift
    declare comment="$1"; shift
    echo "# $comment"
    echo "$destname ()"
    get-bash-function -b "$srcname" || return $?
    echo ''
}

ship-bash-function() {
    declare name="$1"; shift
    declare comment="$1"; shift
    ship-bash-function-as "$name" "$name" "$comment"
}

ship-environment-variable() {
    declare name="$1"; shift
    declare value="$1"; shift
    declare comment="$1"; shift
    if [[ -n "$comment" ]] ; then
        echo "# $comment"
    fi
    printf "export %s=%q\n" "$name" "$value"
}

ship-executable-as-function() {
    declare filename="$1"; shift
    declare functionname="$1"; shift
    declare invocation_interpreter=""
    if [[ $# -gt 0 ]] ; then
        invocation_interpreter="$1 "; shift
    fi
    compressed_content="$(cat "$filename" | gzip -c --best | base64)"
    cat <<EOF
$functionname() {
    declare temp_dir
    set -x
    temp_dir="\$(mktemp -d --tmpdir "$functionname".XXXXXXXXXX)" \
        || echo "Error: Failed to create temporary directory." 1>&2 \
        || return 1
    base64 -d <<"_EOF_" | gzip -c -d >"\$temp_dir/$filename"
$compressed_content
_EOF_
    chmod +x "\$temp_dir/$filename"
    $invocation_interpreter"\$temp_dir/$filename" "\$@"
    echo "Return code: \$?" 1>&2
    rm -rf "\$temp_dir" || echo "Error: Failed to remove temporary directory (exitcode \$?): \$temp_dir" 1>&2
}

EOF
}

main() {
    echo "#!/bin/bash"
    #ship-bash-function ship-bash-function
    ship-executable-as-function "PortForward.java" "portforward_java" "java"
    printf "%q " "portforward_java" "$@"
    echo $'\n'
}

main "$@"
