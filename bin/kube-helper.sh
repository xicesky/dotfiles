#!/bin/bash

KUBE_CONFIG_FILE="${KUBE_CONFIG_FILE:-config}"
KUBE_NAMESPACE="${KUBE_NAMESPACE:-default}"
SPCUSTOMER=""
MIPSERVER_STS=""
MIPSERVER_DEFAULT_CONTAINER=""

# Database connection via psql
PG_AUTH="az-access-token"   # Possible values: password, az-access-token
PGHOST="${PGHOST:-}"
PGPORT="${PGPORT:-5432}"
PGDATABASE="${PGDATABASE:-}"
PGUSER="${PGUSER:-}"
PGPASSWORD="${PGPASSWORD:-}"

# Azure (az) parameters
AZURE_TENANT_ID="${AZURE_TENANT_ID:-16b6f33b-57e2-4e2e-a05b-071e9ce7fc3e}"
AZURE_SUBSCRIPTION_ID="${AZURE_SUBSCRIPTION_ID:-5a8fa46d-0536-4d5b-9c87-99141d740fac}"
AZURE_AKS_NAME="${AZURE_AKS_NAME:-kyma}"
AZURE_AKS_RG="${AZURE_AKS_RG:-kyma-dev}"

# AWS CLI parameters
AWS_PROFILE="${AZURE_AKS_RG:-FLSEKSDeveloper-992695678584}"

config-for-sp-dev() {
    KUBE_CONFIG_FILE="config-az-mx-dev.yaml"
    SPCUSTOMER="$1"
    KUBE_NAMESPACE="$SPCUSTOMER"
    MIPSERVER_STS="${2:-mipserver-$SPCUSTOMER}"
    MIPSERVER_DEFAULT_CONTAINER="${3:-mipserver}" # Old default was mipserver-fla
    # Old variant
    #PGHOST="postgres-shared.postgres.database.azure.com"
    PGHOST="postgres-flexible-mx-sp-priv.postgres.database.azure.com"
    PGDATABASE="postgresqldatabase-${SPCUSTOMER}"
    PGUSER="postgresqldatabase-${SPCUSTOMER}-admin"
    #PGUSER=markus.dangl@solvares.com   # az method doesn't seem to work on dev!?

    AZURE_TENANT_ID="a223fba7-7c90-4a1a-affb-5e6549d0f252"
    AZURE_SUBSCRIPTION_ID="32da1237-4da1-4065-8a2a-37122ce002b1"
    AZURE_AKS_RG="kyma-dev"
}

config-for-sp-dev-new() {
    # Valid for new helm charts

    KUBE_CONFIG_FILE="config-az-mx-dev.yaml"
    SPCUSTOMER="$1"
    KUBE_NAMESPACE="$SPCUSTOMER"
    MIPSERVER_STS="${2:-mipserver}"
    MIPSERVER_DEFAULT_CONTAINER="${2:-mipserver}"
    # Old variant
    #PGHOST="postgres-shared.postgres.database.azure.com"
    PGHOST="postgres-flexible-mx-sp-priv.postgres.database.azure.com"
    PGDATABASE="postgresqldatabase-${SPCUSTOMER}"
    PGUSER="postgresqldatabase-${SPCUSTOMER}-admin"
    #PGUSER=markus.dangl@solvares.com   # az method doesn't seem to work on dev!?

    AZURE_TENANT_ID="a223fba7-7c90-4a1a-affb-5e6549d0f252"
    AZURE_SUBSCRIPTION_ID="32da1237-4da1-4065-8a2a-37122ce002b1"
    AZURE_AKS_RG="kyma-dev"
}

config-for-sp-prod() {
    KUBE_CONFIG_FILE="config-az-mx-prod.yaml"
    SPCUSTOMER="$1"
    KUBE_NAMESPACE="$SPCUSTOMER"
    MIPSERVER_STS="${2:-mipserver-$SPCUSTOMER}"
    MIPSERVER_DEFAULT_CONTAINER="${3:-mipserver}" # Old default was mipserver-fla
    # Old variant
    #PGHOST="postgres-flexible-mx-sp-mip-prod.postgres.database.azure.com"
    PGHOST="postgres-flexible-mx-sp-mip-prod-priv.postgres.database.azure.com"
    PGDATABASE="postgresqldatabase-${SPCUSTOMER}"
    #PGUSER="postgresqldatabase-${SPCUSTOMER}-admin"
    PGUSER=markus.dangl@solvares.com

    AZURE_TENANT_ID="16b6f33b-57e2-4e2e-a05b-071e9ce7fc3e"
    AZURE_SUBSCRIPTION_ID="5a8fa46d-0536-4d5b-9c87-99141d740fac"
    AZURE_AKS_RG="kyma-prod"
}

config-for-sp-prod-new() {
    # Valid for new helm charts

    KUBE_CONFIG_FILE="config-az-mx-prod.yaml"
    SPCUSTOMER="$1"
    KUBE_NAMESPACE="$SPCUSTOMER"
    MIPSERVER_STS="${2:-mipserver}"
    MIPSERVER_DEFAULT_CONTAINER="${2:-mipserver}"
    # Old variant
    #PGHOST="postgres-flexible-mx-sp-mip-prod.postgres.database.azure.com"
    PGHOST="postgres-flexible-mx-sp-mip-prod-priv.postgres.database.azure.com"
    PGDATABASE="postgresqldatabase-${SPCUSTOMER}"
    #PGUSER="postgresqldatabase-${SPCUSTOMER}-admin"
    PGUSER=markus.dangl@solvares.com

    AZURE_TENANT_ID="16b6f33b-57e2-4e2e-a05b-071e9ce7fc3e"
    AZURE_SUBSCRIPTION_ID="5a8fa46d-0536-4d5b-9c87-99141d740fac"
    AZURE_AKS_RG="kyma-prod"
}

config-for-mx-internal() {
    KUBE_CONFIG_FILE="config-mx-internal.yaml"
    KUBE_NAMESPACE="$1"
    #MIPSERVER_STS="$2"
    MIPSERVER_STS="mipserver"
    #MIPSERVER_DEFAULT_CONTAINER="dispatchx-mipserver"
    MIPSERVER_DEFAULT_CONTAINER="mipserver"

    PG_AUTH="password"
    PGHOST="pgsql16-dev.prd.mobilexag.de"
    #PGDATABASE="postgres"
    PGDATABASE="prd_feature_jdk21_db"
    PGUSER=prd_feature_jdk21

    AZURE_TENANT_ID="ac9a92e4-34c9-4fd1-9e08-be7943f659cf"
    AZURE_SUBSCRIPTION_ID="$AZURE_TENANT_ID"    # Subscription: N/A(tenant level account)
    AZURE_AKS_NAME="" # Is not an aks cluster
    AZURE_AKS_RG="" # Is not an aks cluster
}

config-for-local-k3d() {
    KUBE_CONFIG_FILE="config-local-k3d-default.yaml"
    SPCUSTOMER=""
    KUBE_NAMESPACE="default"
    MIPSERVER_DEFAULT_CONTAINER="${2:-mipserver}"
    PG_AUTH="password"
    PGHOST="localhost"
    PGDATABASE="mip-docker"
    PGUSER="postgres"
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
    case "$1" in
        # TODO: Remove -dev option once the dev system is gone.
        *-dev)      PGHOST="ng-mwm-psql.postgres.database.azure.com" ;;
        *-qa)       PGHOST="ng-mwm-psql-dev.postgres.database.azure.com" ;;
        *)          PGHOST="ng-mwm-psql.postgres.database.azure.com" ;;
    esac
    PG_AUTH="password"
    PGDATABASE="${2:-mipserver-mwm-dev}" # Same as the sts name, i.e. mipserver-mwm-dev, mipserver-mwm-prod
    PGUSER="mwmpsqladm"
}

config-for-poseidon() {
    KUBE_CONFIG_FILE="config-aws-poseidon.yaml"
    SPCUSTOMER="$1"
    KUBE_NAMESPACE="$SPCUSTOMER"
    MIPSERVER_STS="${2:-mipserver}"
    MIPSERVER_DEFAULT_CONTAINER="${2:-mipserver}"
    #PGHOST="postgres-flexible-mx-sp-priv.postgres.database.azure.com"
    #PGDATABASE="postgresqldatabase-${SPCUSTOMER}"
    #PGUSER="postgresqldatabase-${SPCUSTOMER}-admin"

    AWS_PROFILE=FLSEKSDeveloper-992695678584
}

load-config() {
    case "$1" in
    #flsa*)              config-for-sp-dev  "customer-687399035" "" "mipserver-fla" ;;  # inactive

    ochs*-dev)          config-for-sp-dev-new   "customer-687399036" ;; # temporarily reactivated for portal-graphql
    ochs*-qa)           config-for-sp-prod-new  "customer-687399031" ;;
    ochs*-prod)         config-for-sp-prod-new  "customer-687399036" ;;

    harg*-dev)          config-for-sp-dev-new   "customer-687399110" ;;
    harg*-prod)         config-for-sp-prod-new  "customer-687399111" ;;
    harg*-sap-qa)       config-for-sp-prod-new  "customer-687399112" ;;
    harg*-qa)           config-for-sp-prod-new  "customer-687399110" ;;

    bwtd*-qa)           config-for-sp-prod-new  "customer-687399060" ;;
    bwtd*-prod)         config-for-sp-prod-new  "customer-687399061" ;;
    bwta*-qa)           config-for-sp-prod-new  "customer-687399200" ;;
    bwta*-prod)         config-for-sp-prod-new  "customer-687399201" ;;

    hsm-qa|hsm-de-qa)       config-for-sp-prod-new  "customer-687399220" ;;
    hsm-prod|hsm-de-prod)   config-for-sp-prod-new  "customer-687399221" ;;
    hsm-uk-qa)              config-for-sp-prod-new  "customer-687399222" ;;
    hsm-uk-prod)            config-for-sp-prod-new  "customer-687399223" ;;
    hsm-fr-qa)              config-for-sp-prod-new  "customer-687399224" ;;
    hsm-fr-prod)            config-for-sp-prod-new  "customer-687399225" ;;
    hsm-pl-qa)              config-for-sp-prod-new  "customer-687399226" ;;
    hsm-pl-prod)            config-for-sp-prod-new  "customer-687399227" ;;
    hsm-es-qa)              config-for-sp-prod-new  "customer-687399228" ;;
    hsm-es-prod)            config-for-sp-prod-new  "customer-687399229" ;;
    hsm-us-qa)              config-for-sp-prod-new  "customer-687399230" ;;
    hsm-us-prod)            config-for-sp-prod-new  "customer-687399231" ;;

    kalt*-qa)           config-for-sp-prod-new  "customer-687399150" ;;
    kalt*-prod)         config-for-sp-prod-new  "customer-687399151" ;;

    gewo*-qa)           config-for-sp-prod-new  "customer-687399170" ;;
    gewo*-prod)         config-for-sp-prod-new  "customer-687399171" ;;

    tria*-qa)           config-for-sp-prod-new  "customer-687399140" ;;
    tria*-prod)         config-for-sp-prod-new  "customer-687399141" ;;

    ware-de-qa)         config-for-sp-prod-new  "customer-687399120" ;;
    ware-de-prod)       config-for-sp-prod-new  "customer-687399121" ;;
    ware-ch-qa)         config-for-sp-prod-new  "customer-687399122" ;;
    ware-ch-prod)       config-for-sp-prod-new  "customer-687399123" ;;
    ware-at-qa)         config-for-sp-prod-new  "customer-687399124" ;;
    ware-at-prod)       config-for-sp-prod-new  "customer-687399125" ;;
    ware-nl-qa)         config-for-sp-prod-new  "customer-687399126" ;;
    ware-nl-prod)       config-for-sp-prod-new  "customer-687399127" ;;

    #solu*-qa)           config-for-sp-prod  "customer-687399180" "" "soluvia-mipserver" ;; # inactive
    #solu*-prod)         config-for-sp-prod  "customer-687399181" "" "soluvia-mipserver" ;; # inactive

    customer-*-qa)      config-for-sp-prod-new "$1" ;;
    customer-*-prod)    config-for-sp-prod-new "$1" ;;
    customer-*)         config-for-sp-dev  "$1" ;;

    oge-dev)            config-for-poseidon "customer-687399362" ;;

    nbb-dev)            config-for-nbb "mwm-dev" "mipserver-mwm-dev" "mipserver-fla" ;;
    nbb-qa)             config-for-nbb "mwm-qa" "mipserver-mwm-qa" "mipserver-fla" ;;
    nbb-prod)           config-for-nbb "mwm-prod" "mipserver-mwm-prod" "mipserver-fla" ;;

    prd-vti)            config-for-mx-internal "vt-integration" "prd-vt-integration-dispatchx-mipserver" ;;
    prd-portal|prd-feature-jdk21)
                        config-for-mx-internal "prd-feature-jdk21" "mipserver";;
    prd-feature-m4q)    config-for-mx-internal "prd-feature-m4q" "mipserver";;
    #abrg|arburg*)       config-for-mx-internal "ps-arburg" "ps-arburg-dispatchx-mipserver" ;; # inactive

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

_ship-executable-as-function() {
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

ship-executable-as-function() {
    _ship-executable-as-function "$@"
}

# kubectl alias with namespace
kube() {
    echo "> $(printf "%q " kubectl -n "$KUBE_NAMESPACE" "$@")" 1>&2
    kubectl -n "$KUBE_NAMESPACE" "$@";
}

kube-list-resources() {
    echo "> $(printf "%q " kubectl api-resources --verbs=list --namespaced -o name)" 1>&2
    kubectl api-resources --verbs=list --namespaced -o name
}

_is_jwt_expired() {
    local current expiry token="$1"; shift
    current="$(date "+%s")"
    expiry="$(jwtutil --decode -j .exp "$token")"
    if [ -z "$expiry" ] ; then
        echo "Error: Invalid token, no .exp field found." 1>&2
        return 1
    fi
    [ "$current" -ge "$expiry" ]
}

_kpsql_precheck() {
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
    case "$(echo "$PG_AUTH" | tr '[:upper:]' '[:lower:]')" in
        password)
            if [[ -z "$PGPASSWORD" ]] ; then
                echo -n "Enter password: "
                read -r -s PGPASSWORD
                if [[ -z "$PGPASSWORD" ]] ; then
                    echo "No password provided." 1>&2
                    return 1
                fi
            fi
            ;;
        az-access-token)
            if [[ -z "$PGPASSWORD" ]] || _is_jwt_expired "$PGPASSWORD" ; then
                PGPASSWORD="$(az account get-access-token --resource-type oss-rdbms --output tsv --query accessToken)"
            fi
            ;;
    esac
}

kpsql() {
    _kpsql_precheck || return $?
    psql "$@"
}

kpsql_remote() {
    _kpsql_precheck || return $?
    # You'll need to override KUBE_NAMESPACE for certain clusters, e.g. KUBE_NAMESPACE="postgresql-client" kpsql
    # This will _NOT_ print the command because it contains the password
    kubectl exec --namespace="$KUBE_NAMESPACE" postgresql-client -it -- \
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
    [[ -z "$pod" && -n "$MIPSERVER_STS" ]] && pod="${MIPSERVER_STS}-0"
    [[ -z "$pod" && -n "$SPCUSTOMER" ]] && pod="mipserver-${SPCUSTOMER}-0"
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
    local options="$1"; shift
    local grep_pattern="$1"; shift
    local level="$1"; shift

    if [[ "$options" != *r* ]] ; then
        pipeline+=(
            # Grep needs to find lines that are json, but not outputs from jboss-cli like `{"outcome" => "success"}`
            "grep --line-buffered -Pe '^\{(?!\"outcome\"\s*=>).*\}\s*$'"
        )
    fi

    # Filter out some noise (raw grep)
    if [[ "$options" != *nf* ]] ; then
        pipeline+=(
            "$(printf "%q " grep --line-buffered -vPe "(No not done journal tx-id found for|<(GetAbsence|GetAbsenceResponse|GetResources|GetResourcesResponse)( [^>]*)?>|PortTypeName: ReadCompleteOrderService)")"
            "$(printf "%q " sed --unbuffered -E \
                -e '/"message":"REQ_IN.*<DynamicChange/s/^\{"timestamp":"([^"]*)".*,"loggerName":"([^"]*)".*,"level":"([^"]*)".*,"message":".*<DynamicChange[^>]+><VTID[^>]+>([^\n<]*)<\/VTID><ExtID[^>]+>([^\n<]*)<\/ExtID><[^>]+>([^\n<]*)<\/FunctionCode><Status[^>]+>([^\n<]*)<\/Status>.*<\/DynamicChange>.*\}$/{"timestamp": "\1","loggerName":"\2","level":"\3_DC_IN","message":"FC \6 \4 \\\"\5\\\" (Status \7)"}/' \
                -e '/"message":"RESP_OUT.*<DynamicChangeResponse/s/^\{"timestamp":"([^"]*)".*,"loggerName":"([^"]*)".*,"level":"([^"]*)".*\}$/{"timestamp": "\1","loggerName":"\2","level":"\3_DC_RESP","message":"ok"}/'
            )"
        )
    fi

    if [[ "$options" == *g* ]] ; then
        pipeline+=( "$(printf "%q " grep --line-buffered -iPe "$grep_pattern")" )
    fi

    # Static json filtering - skipped if "raw"
    if [[ "$options" != *r* ]] ; then

        # Filter out some noise and ignored loggers
        s="$(printf " or contains(\"%s\")" "${ignored_loggers[@]}")"
        s="${s:4}" #; echo "$s" >&2
        pipeline+=( "jq --unbuffered -c 'select(.loggerName | $s | not) | select(.message | contains(\"No not done journal\") | not)'" )
    fi

    # Filter by level if specified
    if [[ -n "$level" ]] ; then
        pipeline+=( "jq --unbuffered -c 'select(.level | test(\"$level\"; \"i\")?)'" )
    fi

    # Static json formatting - skipped if "raw"
    if [[ "$options" != *r* ]] ; then
        # Format output, option "-s" to print stacktrace
        if [[ "$options" == *s* ]] ; then
            pipeline+=( "jq --unbuffered -r '[.level, .timestamp, .loggerName, .message, .stackTrace] | join(\"|\")'" )
        else
            pipeline+=( "jq --unbuffered -r '[.level, .timestamp, .message] | join(\"|\")'" )
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

kmipjavaexec() {
    declare java_file="$1"; shift
    if ! [[ -r "$java_file" ]] ; then
        echo "File does not exist or is not readable: $java_file" 1>&2
        return 1
    fi
    pod="$(_kmip_pod_name "$pod")" || return 1
    kube exec "$pod" -c "$container" -- bash -c "$(_ship-executable-as-function "PortForward.java" "javacode" "java"; printf "%q " "javacode" "$@"; echo $'\n')"
}

kmipdebug() {
    declare pod=""
    [[ "$1" = --pod || "$1" == -p ]] && { shift; pod="$1"; shift; }
    pod="$(_kmip_pod_name "$pod")" || { return 1; }
    #[[ -z "$pod" && -n "$SPCUSTOMER" ]] && pod="mipserver-${SPCUSTOMER}-0"
    kube port-forward "$pod" 8787:8787
}

kmipcli() {
    [[ "$1" = --pod || "$1" == -p ]] && { shift; pod="$1"; shift; }
    pod="$(_kmip_pod_name "$pod")" || { return 1; }

    local connect=true
    local output=json

    local -a jboss_cli_args=()
    if $connect ; then
        jboss_cli_args+=(-c)
    fi
    if [[ "$output" == json ]] ; then
        jboss_cli_args+=(--output-json)
    fi
    jboss_cli_args+=( "$@" )

    # TODO: load properties present on pod
    kmipexec --pod "$pod" /opt/jboss/wildfly/bin/jboss-cli.sh "${jboss_cli_args[@]}"
    # --properties=wildfly-configuration.properties "$@"
}

kmipmgmtconsole() {
    declare pod=""
    [[ "$1" = --pod || "$1" == -p ]] && { shift; pod="$1"; shift; }
    pod="$(_kmip_pod_name "$pod")" || { return 1; }
    #[[ -z "$pod" && -n "$SPCUSTOMER" ]] && pod="mipserver-${SPCUSTOMER}-0"
    echo "Please enter wildfly admin passwort to set:"
    read -rs WILDFLY_ADMIN_PASSWORD
    kmipexec wildfly/bin/add-user.sh -u 'mdangl' -p "$WILDFLY_ADMIN_PASSWORD" -g 'SuperUser'
    kube port-forward "$pod" 9990:9990
}

kmiplogs() {
    declare pod=""
    declare container=""    # previously always "dispatchx-mipserver", now varies
    # TODO: handle --since and --tail, defaulting to --tail=1000 --since=10m
    declare -a kubectl_args=()
    declare json_filter_opts="" json_filter_grep="" json_filter_level=""

    # Parse arguments
    while [[ $# -gt 0 ]] ; do
        if [[ "$1" == '--' || "$1" != -* ]] ; then break; fi
        arg="$1"; shift
        case "$arg" in
        --pod|-p)           pod="$1"; shift ;;
        --container|-c)     container="$1"; shift ;;
        -f|--follow)        kubectl_args+=("$arg") ;;
        --since*|--tail*)   kubectl_args+=("$arg" "$1"); shift ;;
        -g|--grep)          json_filter_opts="${json_filter_opts}g"; json_filter_grep="$1"; shift ;;
        -s|--stacktrace)    json_filter_opts="${json_filter_opts}s" ;;
        --raw)              json_filter_opts="${json_filter_opts}r" ;;
        --level)
            case "$(echo "$1" | tr '[:upper:]' '[:lower:]')" in
            trace|debug) json_filter_level="^(trace|debug|info|warn|err)" ;;
            info) json_filter_level="^(info|warn|err)" ;;
            warn*) json_filter_level="^(warn|err)" ;;
            err*) json_filter_level="^(err)" ;;
            esac
            shift
        ;;
        -*)
            echo "Error: unknown option: $arg" 1>&2
            return 1;
            ;;
        esac
    done

    pod="$(_kmip_pod_name "$pod")" || { return 1; }
    container="$(_kmip_container_name "$container")" || { return 1; }

    declare actual_command
    actual_command="$(printf "%q " kubectl -n "$KUBE_NAMESPACE" logs "$pod" -c "$container" "${kubectl_args[@]}")$(_json_log_filter "$json_filter_opts" "$json_filter_grep" "$json_filter_level")"
    #echo _json_log_filter "$json_filter_opts" "$json_filter_grep" 1>&2
    echo "> $actual_command" 1>&2
    eval "$actual_command"
}

K_OUTPUT_FORMAT="${K_OUTPUT_FORMAT:-yaml}"

_json_to_output_format() {
    case "${K_OUTPUT_FORMAT:-yaml}" in
        yaml) yq -p json -o yaml ;;
        json) jq '.' ;;
        *) echo "Error: Unknown output format: K_OUTPUT_FORMAT=$(printf "%q" "$K_OUTPUT_FORMAT")" 1>&2; return 1 ;;
    esac
}

kargolist() {
    declare namespace=argocd
    if [[ "$1" == "--namespace" ]] ; then
        namespace="$2"; shift 2
    fi
    echo "> $(printf "%q " kubectl get -n "$namespace" applications.argoproj.io)" 1>&2
    kubectl get -n "$namespace" applications.argoproj.io
}

kargoexport() {
    declare namespace=argocd
    if [[ "$1" == "--namespace" ]] ; then
        namespace="$2"; shift 2
    fi
    # Export argocd application
    kubectl get -n "$namespace" applications.argoproj.io "$1" -o json \
        | jq 'del(.status) | .metadata |= with_entries(select(.key == "name" or .key == "namespace"))' \
        | _json_to_output_format
}

kaz() {
    # Parse arguments
    command="$1"; shift
    while [[ $# -gt 0 ]] ; do
        if [[ "$1" == '--' || "$1" != -* ]] ; then break; fi
        arg="$1"; shift
        case "$arg" in
        -*)
            echo "Error: unknown option: $arg" 1>&2
            return 1;
            ;;
        *)
            echo "Error: unknown positional argument: $arg" 1>&2
            return 1;
            ;;
        esac
    done
    case "$command" in
        login)
            echo "$(printf "%q " az login --tenant "$AZURE_TENANT_ID" --use-device-code)" 1>&2
            az login --tenant "$AZURE_TENANT_ID" --use-device-code
            ;;
        set-sub*)
            echo "$(printf "%q " az account set --subscription "$AZURE_SUBSCRIPTION_ID")" 1>&2
            az account set --subscription "$AZURE_SUBSCRIPTION_ID"
            ;;
        generate-kube-config)
            echo "$(printf "%q " az aks get-credentials --resource-group "$AZURE_AKS_RG" --name "$AZURE_AKS_NAME" \
                --file "$KUBECONFIG")" 1>&2
            az aks get-credentials --resource-group "$AZURE_AKS_RG" --name "$AZURE_AKS_NAME" \
                --file "$KUBECONFIG" || return 1
            # Run dos2unix on the kubeconfig file, just to be sure - on windows az generates CRLF line endings
            dos2unix "$KUBECONFIG"
            ;;
        *)
            echo "Error: unknown command: $command" 1>&2
            return 1;
            ;;
    esac
}

cmd_print() {
    # set KUBECONFIG
    ship-environment-variable KUBECONFIG ~/".kube/$KUBE_CONFIG_FILE"
    ship-environment-variable KUBE_NAMESPACE "$KUBE_NAMESPACE"
    ship-environment-variable K_OUTPUT_FORMAT "$K_OUTPUT_FORMAT"
    ship-environment-variable SPCUSTOMER "$SPCUSTOMER"
    ship-environment-variable MIPSERVER_STS "$MIPSERVER_STS"
    ship-environment-variable MIPSERVER_DEFAULT_CONTAINER "$MIPSERVER_DEFAULT_CONTAINER"
    ship-environment-variable PGHOST "$PGHOST"
    ship-environment-variable PGPORT "$PGPORT"
    ship-environment-variable PGDATABASE "$PGDATABASE"
    ship-environment-variable PGUSER "$PGUSER"
    ship-environment-variable PG_AUTH "$PG_AUTH"
    # Note: Do not ship PGPASSWORD for security reasons
    #ship-environment-variable PGPASSWORD "$PGPASSWORD"
    printf "export %s\n" "PGPASSWORD"
    ship-environment-variable AZURE_TENANT_ID "$AZURE_TENANT_ID"
    ship-environment-variable AZURE_SUBSCRIPTION_ID "$AZURE_SUBSCRIPTION_ID"
    ship-environment-variable AZURE_AKS_NAME "$AZURE_AKS_NAME"
    ship-environment-variable AZURE_AKS_RG "$AZURE_AKS_RG"

    ship-bash-function kube "kubctl alias with namespace"
    ship-bash-function kube-list-resources "list all kubernetes resource types"
    ship-bash-function _is_jwt_expired "internal use only"
    ship-bash-function _kpsql_precheck "internal use only"
    ship-bash-function kpsql "run psql locally"
    ship-bash-function kpsql_remote "run psql on the postgresql-client pod"
    ship-bash-function _kmip_pod_name "internal use only"
    ship-bash-function _kmip_container_name "internal use only"
    ship-bash-function _json_log_filter "internal use only"
    ship-bash-function _json_to_output_format "internal use only"
    ship-bash-function kmipexec_usage "usage for kmipexec"
    ship-bash-function kmipexec "execute command on mipserver pod"
    ship-bash-function _ship-executable-as-function "internal use only"
    ship-bash-function kmipjavaexec "execute java code on mipserver pod"
    ship-bash-function kmiplogs "get logs of mipserver pod"
    ship-bash-function kmipdebug "foward port 8787"
    ship-bash-function kmipcli "run jboss-cli.sh on mipserver pod"
    ship-bash-function kmipmgmtconsole "add user, foward port 9990"
    ship-bash-function kargolist "list argocd applications"
    ship-bash-function kargoexport "export argocd application"
    ship-bash-function kaz "wrapper for azure az commands"
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
