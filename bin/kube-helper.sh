#!/bin/bash

KUBE_CONFIG_FILE="${KUBE_CONFIG_FILE:-config}"
KUBE_NAMESPACE="${KUBE_NAMESPACE:-default}"
SPCUSTOMER=""
MIPSERVER_STS=""
MIPSERVER_DEFAULT_CONTAINER=""

# Database connection via psql
PGHOST="${PGHOST:-}"
PGPORT="${PGPORT:-5432}"
PGDATABASE="${PGDATABASE:-}"
PGUSER="${PGUSER:-}"
PGPASSWORD="${PGPASSWORD:-}"

config-for-sp() {
    KUBE_CONFIG_FILE="config-az-mx-dev.yaml"
    SPCUSTOMER="$1"
    KUBE_NAMESPACE="$SPCUSTOMER"
    MIPSERVER_STS="${2:-mipserver-$SPCUSTOMER}"
    MIPSERVER_DEFAULT_CONTAINER="${2:-mipserver-fla}"
}

config-for-sp-prod() {
    KUBE_CONFIG_FILE="config-az-mx-prod.yaml"
    SPCUSTOMER="$1"
    KUBE_NAMESPACE="$SPCUSTOMER"
    MIPSERVER_STS="${2:-mipserver-$SPCUSTOMER}"
    MIPSERVER_DEFAULT_CONTAINER="${2:-mipserver-fla}"
}

config-for-mx-internal() {
    KUBE_CONFIG_FILE="config-mx-internal.yaml"
    KUBE_NAMESPACE="$1"
    MIPSERVER_STS="$2"
    MIPSERVER_DEFAULT_CONTAINER="dispatchx-mipserver"
}

config-for-local-k3d() {
    KUBE_CONFIG_FILE="config-local-k3d-default.yaml"
    SPCUSTOMER=""
    KUBE_NAMESPACE="default"
    MIPSERVER_DEFAULT_CONTAINER="${2:-mipserver}"
}

config-for-qub1c() {
    KUBE_CONFIG_FILE="config-qub1c.yaml"
    SPCUSTOMER=""
    KUBE_NAMESPACE="default"
    MIPSERVER_DEFAULT_CONTAINER="${2:-mipserver}"
}

config-for-nbb() {
    # This is used on the bastion host, the kubeconfig is already set
    KUBE_CONFIG_FILE="config"
    SPCUSTOMER=""
    KUBE_NAMESPACE="$1"
    MIPSERVER_STS="${2:-mipserver-mwm-dev}"
    MIPSERVER_DEFAULT_CONTAINER="${3:-mipserver-fla}"
    PGHOST="ng-mwm-psql.postgres.database.azure.com"
    PGDATABASE="${2:-mipserver-mwm-dev}" # Same as the sts name, i.e. mipserver-mwm-dev, mipserver-mwm-prod
    PGUSER="mwmpsqladm"
}

load-config() {
    case "$1" in
    flsa*)              config-for-sp "customer-687399035" ;;

    ochs*-qa)           config-for-sp-prod  "customer-687399031" ;;
    ochs*-prod)         config-for-sp-prod  "customer-687399036" ;;
    ochs*-dev)          config-for-sp       "customer-687399036" ;;

    bwtd*-qa)           config-for-sp-prod  "customer-687399060" "bwt-de-mipserver" ;;
    bwtd*-prod)         config-for-sp-prod  "customer-687399061" "bwt-de-mipserver" ;;
    bwta*-qa)           config-for-sp-prod  "customer-687399200" "bwt-at-mipserver" ;;
    bwta*-prod)         config-for-sp-prod  "customer-687399201" "bwt-at-mipserver" ;;

    harg*-qa)           config-for-sp-prod  "customer-687399110" ;;
    #harg*-prpd)         config-for-sp-prod  "customer-687399111" ;;
    #harg*)              config-for-sp      "customer-687399110" ;;

    kalt*-qa)           config-for-sp-prod  "customer-687399150" kaltenbach-mipserver ;;
    kalt*-prod)         config-for-sp-prod  "customer-687399151" kaltenbach-mipserver ;;
    gewo*-qa)           config-for-sp-prod  "customer-687399170" gewofag-mipserver ;;
    gewo*-prod)         config-for-sp-prod  "customer-687399171" gewofag-mipserver ;;
    solu*-qa)           config-for-sp-prod  "customer-687399180" soluvia-mipserver ;;
    #solu*-prod)         config-for-sp-prod  "customer-687399181" soluvia-mipserver ;;

    customer-*-qa)      config-for-sp-prod "$1" ;;
    customer-*-prod)    config-for-sp-prod "$1" ;;
    customer-*)         config-for-sp "$1" ;;

    nbb-dev)            config-for-nbb "mwm-dev" "mipserver-mwm-dev" ;;
    nbb-prod)           config-for-nbb "mwm-prod" "mipserver-mwm-prod" ;;

    prd-vti)            config-for-mx-internal "vt-integration" "prd-vt-integration-dispatchx-mipserver" ;;
    abrg|arburg*)       config-for-mx-internal "ps-arburg" "ps-arburg-dispatchx-mipserver" ;;
    qub1c)              config-for-qub1c "$1" ;;
    local*)             config-for-local-k3d "$1" ;;
    *)                  return 1 ;;
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

ship-environment-variable() {
    declare name="$1"; shift
    declare value="$1"; shift
    declare comment="$1"; shift
    if [[ -n "$comment" ]] ; then
        echo "# $comment"
    fi
    printf "export %s=%q\n" "$name" "$value"
}

# kubectl alias with namespace
kube() {
    echo "> $(printf "%q " kubectl -n "$KUBE_NAMESPACE" "$@")" 1>&2
    kubectl -n "$KUBE_NAMESPACE" "$@";
}

kpsql() {
    if [[ -z "$PGHOST" ]] ; then
        echo "No database host set. (PGHOST)" 1>&2
        return 1
    fi
    if [[ -z "$PGDATABASE" ]] ; then
        echo "No database name set. (PGDATABASE)" 1>&2
        return 1
    fi
    if [[ -z "$PGUSER" ]] ; then
        echo "No database user set. (PGUSER)" 1>&2
        return 1
    fi
    if [[ -z "$PGPASSWORD" ]] ; then
        read -r -s -p "Enter password: " PGPASSWORD
    fi
    # This will _NOT_ print the command because it contains the password
    kubectl exec --namespace=postgresql-client postgresql-client -it -- \
        env PGHOST="$PGHOST" PGPORT="$PGPORT" PGDATABASE="$PGDATABASE" PGUSER="$PGUSER" PGPASSWORD="$PGPASSWORD" PSQL_PAGER= \
        psql "$@"
}

kmipexec_usage() {
    echo "Usage: kmipexec [-p <podname>|--pod <podname>] [-c <container>|--container <container>] <command ...>"
    echo "    e.g.: kmipexec -p mipserver-customer-687399036-0 -c dispatchx-mipserver bash"
    [[ -n "$1" ]] && { echo "    podname defaults to: $1"; shift; }
    [[ -n "$1" ]] && { echo "    container defaults to: $1"; shift; }
}

_kmip_pod_name() {
    declare pod="$1"
    [[ -z "$pod" && -n "$SPCUSTOMER" ]] && pod="mipserver-${SPCUSTOMER}-0"
    [[ -z "$pod" && -n "$MIPSERVER_STS" ]] && pod="${MIPSERVER_STS}-0"
    if [[ -z "$pod" ]] ; then
        echo "No pod name provided and no serviceplatform customer (SPCUSTOMER variable) set." 1>&2
        return 1
    fi
    echo "$pod"
}

_kmip_container_name() {
    declare container="$1"
    [[ -z "$container" && -n "$MIPSERVER_DEFAULT_CONTAINER" ]] && container="$MIPSERVER_DEFAULT_CONTAINER"

    if [[ -z "$container" ]] ; then
        echo "No container name provided and no serviceplatform customer (SPCUSTOMER variable) set." 1>&2
        return 1
    fi
    echo "$container"
}

function join_by {
  local d=${1-} f=${2-}
  if shift 2; then
    printf %s "$f" "${@/#/$d}"
  fi
}

_json_log_filter() {
    declare -a pipeline=()
    declare -a ignored_loggers=(AvailabilityTimeMerger VisitourPollAvailabilityJob ReflectionServiceFactoryBean)
    declare s

    if [[ "$1" != *r* ]] ; then
        pipeline+=(
            # Grep needs to find lines that are json, but not outputs from jboss-cli like `{"outcome" => "success"}`
            "grep -Pe '^\{(?!\"outcome\"\s*=>).*\}\s*$'"
        )
    fi

    # Filter out some noise (raw grep)
    if [[ "$1" != *nf* ]] ; then
        pipeline+=(
            "$(printf "%q " grep -vPe "(No not done journal tx-id found for|<(GetAbsence|GetAbsenceResponse|GetResources|GetResourcesResponse)( [^>]*)?>|PortTypeName: ReadCompleteOrderService)")"
            "$(printf "%q " sed -E \
                -e '/"message":"REQ_IN.*<DynamicChange/s/^\{"timestamp":"([^"]*)".*,"loggerName":"([^"]*)".*,"level":"([^"]*)".*,"message":".*<DynamicChange[^>]+><VTID[^>]+>([^\n<]*)<\/VTID><ExtID[^>]+>([^\n<]*)<\/ExtID><[^>]+>([^\n<]*)<\/FunctionCode><Status[^>]+>([^\n<]*)<\/Status>.*<\/DynamicChange>.*\}$/{"timestamp": "\1","loggerName":"\2","level":"\3_DC_IN","message":"FC \6 \4 \\\"\5\\\" (Status \7)"}/' \
                -e '/"message":"RESP_OUT.*<DynamicChangeResponse/s/^\{"timestamp":"([^"]*)".*,"loggerName":"([^"]*)".*,"level":"([^"]*)".*\}$/{"timestamp": "\1","loggerName":"\2","level":"\3_DC_RESP","message":"ok"}/'
            )"
        )
    fi

    if [[ "$1" == *g* ]] ; then
        pipeline+=( "$(printf "%q " grep -iPe "$2")" )
    fi

    # Json filtering and formatting - skipped if "raw"
    if [[ "$1" != *r* ]] ; then

        # Filter out some noise and ignored loggers
        s="$(printf " or contains(\"%s\")" "${ignored_loggers[@]}")"
        s="${s:4}" #; echo "$s" >&2
        pipeline+=( "jq -c 'select(.loggerName | $s | not) | select(.message | contains(\"No not done journal\") | not)'" )

        # Format output, option "-s" to print stacktrace
        if [[ "$1" == *s* ]] ; then
            pipeline+=( "jq -r '[.level, .timestamp, .loggerName, .message, .stackTrace] | join(\"|\")'" )
        else
            pipeline+=( "jq -r '[.level, .timestamp, .message] | join(\"|\")'" )
        fi
    fi
    
    #pipeline+=( "column -t -s '|'" )
    
    #command=$(printf " | %s" "${pipeline[@]}")
    #echo "${command:3}"
    if [ ${#pipeline[@]} -gt 0 ]; then
        printf " \\\\\n     | %s" "${pipeline[@]}"
    fi
}

# execute command on mipserver pod
kmipexec() {
    declare pod=""
    declare container=""    # previously always "dispatchx-mipserver", now varies

    # Parse arguments
    while [[ $# -gt 0 ]] ; do
        if [[ "$1" == '--' || "$1" != -* ]] ; then break; fi
        arg="$1"; shift
        case "$arg" in
        --pod|-p)           pod="$1"; shift ;;
        --container|-c)     container="$1"; shift ;;
        esac
    done

    pod="$(_kmip_pod_name "$pod")" || { kmipexec_usage 1>&2; return 1; }
    container="$(_kmip_container_name "$container")" || { kmipexec_usage 1>&2; return 1; }

    [[ "$#" -lt 1 ]] && {
        kmipexec_usage "$pod" "$container" 1>&2
        return 1
    }
    kube exec "$pod" -it -c "$container" -- "$@";
}

kmipdebug() {
    declare pod=""
    [[ "$1" = --pod || "$1" == -p ]] && { shift; pod="$1"; shift; }
    pod="$(_kmip_pod_name "$pod")" || { return 1; }
    #[[ -z "$pod" && -n "$SPCUSTOMER" ]] && pod="mipserver-${SPCUSTOMER}-0"
    kube port-forward "$pod" 8787:8787
}

kmiplogs() {
    declare pod=""
    declare container=""    # previously always "dispatchx-mipserver", now varies
    # TODO: handle --since and --tail, defaulting to --tail=1000 --since=10m
    declare -a kubectl_args=()
    declare json_filter_arg0="" json_filter_arg1=""

    # Parse arguments
    while [[ $# -gt 0 ]] ; do
        if [[ "$1" == '--' || "$1" != -* ]] ; then break; fi
        arg="$1"; shift
        case "$arg" in
        --pod|-p)           pod="$1"; shift ;;
        --container|-c)     container="$1"; shift ;;
        -f|--follow)        kubectl_args+=("$arg") ;;
        --since*|--tail*)   kubectl_args+=("$arg" "$1"); shift ;;
        -g|--grep)          json_filter_arg0="${json_filter_arg0}g"; json_filter_arg1="$1"; shift ;;
        -s|--stacktrace)    json_filter_arg0="${json_filter_arg0}s" ;;
        --raw)              json_filter_arg0="${json_filter_arg0}r" ;;
        esac
    done

    pod="$(_kmip_pod_name "$pod")" || { return 1; }
    container="$(_kmip_container_name "$container")" || { return 1; }

    declare actual_command
    actual_command="$(printf "%q " kubectl -n "$KUBE_NAMESPACE" logs "$pod" -c "$container" "${kubectl_args[@]}")$(_json_log_filter "$json_filter_arg0" "$json_filter_arg1")"
    #echo _json_log_filter "$json_filter_arg0" "$json_filter_arg1" 1>&2
    echo "> $actual_command" 1>&2
    eval "$actual_command"
}

cmd_print() {
    # set KUBECONFIG
    ship-environment-variable KUBECONFIG ~/".kube/$KUBE_CONFIG_FILE"
    ship-environment-variable KUBE_NAMESPACE "$KUBE_NAMESPACE"
    ship-environment-variable SPCUSTOMER "$SPCUSTOMER"
    ship-environment-variable MIPSERVER_STS "$MIPSERVER_STS"
    ship-environment-variable MIPSERVER_DEFAULT_CONTAINER "$MIPSERVER_DEFAULT_CONTAINER"
    ship-environment-variable PGHOST "$PGHOST"
    ship-environment-variable PGPORT "$PGPORT"
    ship-environment-variable PGDATABASE "$PGDATABASE"
    ship-environment-variable PGUSER "$PGUSER"
    # Note: Do not ship PGPASSWORD for security reasons
    #ship-environment-variable PGPASSWORD "$PGPASSWORD"

    ship-bash-function kube "kubctl alias with namespace"
    ship-bash-function kpsql "run psql on the postgresql-client pod"
    ship-bash-function _kmip_pod_name "internal use only"
    ship-bash-function _kmip_container_name "internal use only"
    ship-bash-function _json_log_filter "internal use only"
    ship-bash-function kmipexec_usage "usage for kmipexec"
    ship-bash-function kmipexec "execute command on mipserver pod"
    ship-bash-function kmiplogs "get logs of mipserver pod"
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
