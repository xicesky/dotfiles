#!/bin/bash

SPCUSTOMER="${SPCUSTOMER:-"customer-687399035"}"

remap-sp-customer() {
    case "$1" in
    harg*)      echo "customer-687399035" ;;
    ochs*)      echo "customer-687399036" ;;
    customer-*) echo "$1" ;;
    *)          return 1 ;;
    esac
}

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

# kubectl alias with namespace
kube() { kubectl -n "$SPCUSTOMER" "$@"; }

# execute command on mipserver pod
kmipexec() {
    declare pod="mipserver-${SPCUSTOMER}-0"
    [[ "$1" = --pod || "$1" == -p ]] && { shift; pod="$1"; shift; }
    [[ "$#" -lt 1 ]] && {
        echo "Usage: kmipexec [-p <podname>|--pod <podname>] <command ...>" 1>&2
        echo "    e.g.: kmipexec -p mipserver-customer-687399036-0 bash" 1>&2
        echo "    podname defaults to: $pod" 1>&2
        return 1
    }
    MSYS2_ARG_CONV_EXCL="*" kube exec "$pod" -it -c dispatchx-mipserver -- "$@"; 
}

kmipdebug() {
    declare pod="mipserver-${SPCUSTOMER}-0"
    [[ "$1" = --pod || "$1" == -p ]] && { shift; pod="$1"; shift; }
    kube port-forward "$pod" 8787:8787
}

cmd_print() {
    # set KUBECONFIG
    echo "export KUBECONFIG=~/.kube/az-mx-dev-kubeconfig.yaml"
    echo "export SPCUSTOMER=\"$SPCUSTOMER\""
    ship-bash-function kube "kubctl alias with namespace"
    ship-bash-function kmipexec "execute command on mipserver pod"
    ship-bash-function kmipdebug "foward port 8787"
}


help() {
    echo "Sorry, help NYI"
}

main() {
    declare command=print
    declare arg

    # Parse arguments
    declare argi=0
    while [[ $# -gt 0 ]] ; do
        arg="$1"; shift
        if [[ "$arg" != -* ]]; then (( argi++ )); fi
        case "$arg" in
        *)
            case "$argi" in
            1)
                SPCUSTOMER="$arg"
                ;;
            *)
                echo "Error: unknown positional argument #$argi: $arg" 1>&2
                echo "    ... here's the help:" 1>&2
                help
                return 1;
                ;;
            esac
            ;;
        esac
    done

    declare temp_customer
    temp_customer="$(remap-sp-customer "${SPCUSTOMER}")" || {
        echo "Unknown serviceplatform customer: $SPCUSTOMER" 1>&2
        return 1
    }
    SPCUSTOMER="$temp_customer"

    declare exitcode=0
    "cmd_$command" "$@"
    exitcode="$?"
    # if [[ "$exitcode" -ne 0 ]] ; then
    #     echo ""
    #     report_command_failure
    #     echo ""
    # fi
    return $exitcode
}

main "$@"
