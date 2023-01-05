#!/bin/bash

KUBE_CONFIG_FILE="${KUBE_CONFIG_FILE:-config}"
KUBE_NAMESPACE="${KUBE_NAMESPACE:-default}"
SPCUSTOMER="${SPCUSTOMER:-"customer-687399035"}"

config-for-sp() {
    KUBE_CONFIG_FILE="config-az-mx-dev.yaml"
    SPCUSTOMER="$1"
    KUBE_NAMESPACE="$SPCUSTOMER"
}

config-for-local-k3d() {
    KUBE_CONFIG_FILE="config-local-k3d-default.yaml"
    SPCUSTOMER=""
    KUBE_NAMESPACE="default"
}

config-for-qub1c() {
    KUBE_CONFIG_FILE="config-qub1c.yaml"
    SPCUSTOMER=""
    KUBE_NAMESPACE="default"
}

load-config() {
    case "$1" in
    harg*)      config-for-sp "customer-687399035" ;;
    ochs*)      config-for-sp "customer-687399036" ;;
    customer-*) config-for-sp "$1" ;;
    qub1c)      config-for-qub1c "$1" ;;
    local*)     config-for-local-k3d "$1" ;;
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
kube() { kubectl -n "$KUBE_NAMESPACE" "$@"; }

kmipexec_usage() {
    echo "Usage: kmipexec [-p <podname>|--pod <podname>] <command ...>"
    echo "    e.g.: kmipexec -p mipserver-customer-687399036-0 bash"
    [[ -n "$1" ]] && echo "    podname defaults to: $pod"
}

# execute command on mipserver pod
kmipexec() {
    declare pod=""
    [[ "$1" = --pod || "$1" == -p ]] && { shift; pod="$1"; shift; }
    [[ -z "$pod" && -n "$SPCUSTOMER" ]] && pod="mipserver-${SPCUSTOMER}-0"
    if [[ -z "$pod" ]] ; then
        echo "No pod name provided and no serviceplatform customer (SPCUSTOMER variable) set." 1>&2
        kmipexec_usage 1>&2
        return 1
    fi
    [[ "$#" -lt 1 ]] && {
        kmipexec_usage "$pod" 1>&2
        return 1
    }
    MSYS2_ARG_CONV_EXCL="*" kube exec "$pod" -it -c dispatchx-mipserver -- "$@"; 
}

kmipdebug() {
    declare pod=""
    [[ "$1" = --pod || "$1" == -p ]] && { shift; pod="$1"; shift; }
    [[ -z "$pod" && -n "$SPCUSTOMER" ]] && pod="mipserver-${SPCUSTOMER}-0"
    kube port-forward "$pod" 8787:8787
}

cmd_print() {
    # set KUBECONFIG
    echo "export KUBECONFIG=~/.kube/$KUBE_CONFIG_FILE"
    echo "export KUBE_NAMESPACE=\"$KUBE_NAMESPACE\""
    echo "export SPCUSTOMER=\"$SPCUSTOMER\""

    ship-bash-function kube "kubctl alias with namespace"
    ship-bash-function kmipexec_usage "usage for kmipexec"
    ship-bash-function kmipexec "execute command on mipserver pod"
    ship-bash-function kmipdebug "foward port 8787"
}

help() {
    echo "Sorry, help NYI"
}

main() {
    declare command=print
    declare arg
    declare target_config=""

    # Parse arguments
    declare argi=0
    while [[ $# -gt 0 ]] ; do
        arg="$1"; shift
        if [[ "$arg" != -* ]]; then (( argi++ )); fi
        case "$arg" in
        *)
            case "$argi" in
            1)
                target_config="$arg"
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

    if [[ -z "$target_config" ]] ; then
        {
            echo "Available configs:"
            echo "    customer-*      Serviceplatform customer namespace"
            echo "    hargi           Shortcut for sp hargassner"
            echo "    ochsi           Shortcut for sp ochsner"
            echo "    qub1c           qub1c.q1cc.net default namespace"
            echo "    local           Local k3d"
        } 1>&2
        return 0
    fi

    load-config "$target_config" || {
        echo "Unknown config: $target_config" 1>&2
        return 1
    }

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
