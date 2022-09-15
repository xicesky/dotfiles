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

# set KUBECONFIG
echo "export KUBECONFIG=~/.kube/az-mx-dev-kubeconfig.yaml"

# kubectl alias with namespace
kube() { kubectl -n customer-687399036 "$@"; }
# execute command on mipserver pod
kmipexec() { 
    [[ "$#" -lt 2 ]] && {
        echo "Usage: kmipexec <pod> <command ...>" 1>&2
        echo "e.g.: kmipexec mipserver-customer-687399036-0 bash" 1>&2
        return 1
    }
    declare pod="$1"; shift; MSYS2_ARG_CONV_EXCL="*" kube exec "$pod" -it -c dispatchx-mipserver -- "$@"; 
}

ship-bash-function kube "kubctl alias with namespace"
ship-bash-function kmipexec "execute command on mipserver pod"
