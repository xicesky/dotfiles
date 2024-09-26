#!/bin/bash
# OAuth2 client in bash, requires a bunch of utilities:
#   - The accompanying jwtutil script
#   - Which in turn needs basenc from coreutils >= 8.31
#   - ... and openssl for signing JWTs
#   - jq for JSON parsing
#   - curl for HTTP requests
# Currently only supports the client credentials and device flow

################################################################################
# Verbosity, command logging

# Verbosity level, 0 is quiet, 1 is normal, 2 prints commands
VERBOSITY="${VERBOSITY:-1}"
DEBUG_TOKEN="${DEBUG_TOKEN:-false}"

# Don't act, just check (and print commands)
NO_ACT="${NO_ACT:-false}"

# Display a message if verbosity level allows
log() {
    declare prefix="$DEFAULT_LOG_PREFIX"
    [[ "$1" = "-p" ]] && { shift; prefix="$1"; shift; }
    declare level="$1"; shift
    if [[ "$VERBOSITY" -ge "$level" ]] ; then
        echo "$prefix$*" 1>&2
    fi
}

# Same but use printf
logf() {
    declare level="$1"; shift
    # Passing a formatting string is exactly what we intend here
    # shellcheck disable=SC2059
    log "$level" "$(printf "$@")"
}

# Stores the last command executed by invoke()
declare -a LAST_COMMAND
LAST_COMMAND=()

# ... and it's exit code
declare -g LAST_COMMAND_EXITCODE
LAST_COMMAND_EXITCODE=0

# Log and invoke a command or skip it if NO_ACT is set
# This actually works only for simple commands, you can't use it to:
#   - Invoke commands that use pipes or redirections
#   - Invoke compound commands (expressions)
#   - Set variables
invoke() {
    declare redir=""
    declare loglevel=2
    while [[ $# -gt 0 ]] ; do
        case "$1" in
            "-o")   shift; redir="$1"; shift ;;
            "-l")   shift; loglevel="$1"; shift ;;
            "--")   shift; break ;;
            -*)     echo "invoke: Unknown flag: $arg" 1>&2; return 1 ;;
            *)      break ;;
        esac
    done
    LAST_COMMAND=("$@")
    log -p "" "$loglevel" "$(printf "%q " "$@")${redir:+ >$redir}"
    if ! "$NO_ACT" ; then
        LAST_COMMAND_EXITCODE=0
        if [[ -z "$redir" ]] ; then "$@"; else "$@" >"$redir"; fi
        LAST_COMMAND_EXITCODE="$?"
        return $LAST_COMMAND_EXITCODE
    fi
}

# Report the last command, if it failed
report_command_failure() {
    if [[ "$LAST_COMMAND_EXITCODE" -ne 0 ]] ; then
        log 1 "Last command executed:"
        log 1 "    $(printf "%q " "${LAST_COMMAND[@]}")"
        log 1 "Returned exit code ${LAST_COMMAND_EXITCODE}"
    fi
}

################################################################################
# Temp dir handling

# Stores the name of the temporary directory, if it was created
declare -g SCRIPT_TEMP_DIR="${SCRIPT_TEMP_DIR:-}"
declare -g THIS_SCRIPT_NAME
THIS_SCRIPT_NAME="$(basename "$0")"

# Create temporary directory (once) and return its name
# This still works when NO_ACT is set, because the effect is only temporary
require-temp-dir() {
    if [[ -z "$SCRIPT_TEMP_DIR" ]] ; then
        SCRIPT_TEMP_DIR="$(mktemp -d --tmpdir "$THIS_SCRIPT_NAME".XXXXXXXXXX)" \
            || echo "Error: Failed to create temporary directory." 1>&2 \
            || return $?
        # Remove temporary directory when this script finishes
        trap 'remove-temp-dir' EXIT
    fi
}

# Remove temporary directory if it was ever created
remove-temp-dir() {
    if [[ -n "$SCRIPT_TEMP_DIR" ]] ; then
        log 2 "# Removing temporary directory: $SCRIPT_TEMP_DIR"
        rm -rf "$SCRIPT_TEMP_DIR" \
            || echo "Error: Failed to remove temporary directory (exitcode $?): $SCRIPT_TEMP_DIR" 1>&2
        SCRIPT_TEMP_DIR=''
    fi
}

################################################################################
# Utilities

# Search for the given executable in PATH
# avoids a dependency on the `which` command
which() {
  # Alias to Bash built-in command `type -P`
  type -P "$@"
}

################################################################################
# Configuration

# TODO: Fetch info from .well-known/openid-configuration
# curl "https://idp.kyma-dev.mobilex-serviceplatform.com/auth/realms/ProductDevelopment/.well-known/openid-configuration" | jq .

CONFIG_MODE="${OAUTH_MODE:-oidc}"                   # Possible modes: oauth2, oidc, mx-configuration
DEFAULT_LOGIN_MODE="${DEFAULT_LOGIN_MODE:-device}"  # Possible modes: client-credentials, device

# For mode "mx-configuration" only
MX_CUSTOMER="${MX_CUSTOMER:-687399110}"
MX_BASEURL="${MX_BASEURL:-https://customer-${MX_CUSTOMER}.serviceplatform.eu/}"

# For mode "oidc" only
OIDC_BASEURL="${OIDC_BASEURL:-https://idp.serviceplatform.eu/auth/realms/customer-${MX_CUSTOMER}/}"

# For mode "oauth2" only
OAUTH2_TOKEN_ENDPOINT="${OAUTH2_ENDPOINT:-"https://idp.kyma-dev.mobilex-serviceplatform.com/auth/realms/customer-${MX_CUSTOMER}/protocol/openid-connect/token"}"
OAUTH2_DEVICE_AUTHORIZATION_ENDPOINT="${OAUTH2_DEVICE_AUTHORIZATION_ENDPOINT:-"https://idp.kyma-dev.mobilex-serviceplatform.com/auth/realms/customer-${MX_CUSTOMER}/protocol/openid-connect/auth/device"}"

# Other oauth options
OAUTH2_CLIENT_ID="${OAUTH2_CLIENT_ID:-postman}"     # Alternatives: curl-cli, customer-backend
OAUTH2_CLIENT_SECRET="$OAUTH2_CLIENT_SECRET"
OAUTH2_SCOPE="${OAUTH2_SCOPE:-openid}"              # Alternative: openid profile
OAUTH2_AUDIENCE="${OAUTH2_AUDIENCE:-mip-server}"
OAUTH2_ACCESS_TOKEN="$OAUTH2_ACCESS_TOKEN"

# Keycloak API
KEYCLOAK_READ_TOKEN_ENDPOINT="https://idp.serviceplatform.eu/auth/realms/customer-${MX_CUSTOMER}/broker/oidc/token"

# Output format
OUTPUT_FORMAT="bash"

# Minor config cleanups
MX_BASEURL="${MX_BASEURL%/}"        # Remove trailing slash
OIDC_BASEURL="${OIDC_BASEURL%/}"    # Remove trailing slash

################################################################################
# Library functions

configure_via_oidc() {
    local openid_configuration
    # FIXME: Handle HTTP errors
    openid_configuration="$(
        invoke curl -s "${OIDC_BASEURL}/.well-known/openid-configuration"
    )" || return 1
    #echo "openid_configuration:"
    #echo "$openid_configuration" | jq .
    OAUTH2_TOKEN_ENDPOINT="$(echo "$openid_configuration" | jq -r .token_endpoint)"
    OAUTH2_DEVICE_AUTHORIZATION_ENDPOINT="$(echo "$openid_configuration" | jq -r .device_authorization_endpoint)"
    
}

configure_via_mx_configuration() {
    local mx_configuration
    # FIXME: Handle HTTP errors
    mx_configuration="$(
        invoke curl -s "${MX_BASEURL}/.well-known/mx-configuration"
    )" || return 1
    OIDC_BASEURL="$(echo "$mx_configuration" | jwtutil --decode | jq -r .openidConnectAuthority)" || return 1
    OIDC_BASEURL="${OIDC_BASEURL%/}"    # Remove trailing slash
    configure_via_oidc
}

configure() {
    case "$CONFIG_MODE" in
        oauth2)
            # Nothing to do
            return 0
            ;;
        oidc)
            configure_via_oidc
            return $?
            ;;
        mx-configuration)
            configure_via_mx_configuration
            return $?
            ;;
        *)
            echo "Error: Unknown CONFIG_MODE $CONFIG_MODE!" 1>&2
            return 1
    esac
}

verify_token_signature() {
    local token="$1"; shift
    # TODO :/
    true
}

is_token_expired() {
    local current expiry token="$1"; shift
    current="$(date "+%s")"
    expiry="$(echo "$token" | jwtutil --decode | jq -r .exp)"
    if [ -z "$expiry" ] ; then
        echo "Error: Invalid token, no .exp field found." 1>&2
        return 0
    fi
    #echo "current=$current"
    #echo "expiry=$expiry"
    [ "$current" -ge "$expiry" ]
}

# Only used during login functions
OAUTH2_RESPONSE_JSON=""

login_via_client_credentials() {
    declare access_token
    if [[ -z "$OAUTH2_CLIENT_SECRET" ]] ; then
        echo "Error: OAUTH2_CLIENT_SECRET is not set" 1>&2
        return 1
    fi

    configure || return $?

    # FIXME: Handle HTTP errors
    OAUTH2_RESPONSE_JSON="$(
        invoke curl -s -X POST \
            --url "${OAUTH2_TOKEN_ENDPOINT}" \
            --header 'Content-Type: application/x-www-form-urlencoded' \
            --data 'grant_type=client_credentials' \
            --data "client_id=$OAUTH2_CLIENT_ID" \
            --data "client_secret=$OAUTH2_CLIENT_SECRET" \
            --data "audience=$OAUTH2_AUDIENCE"
    )"
    OAUTH2_ACCESS_TOKEN="$(echo "$OAUTH2_RESPONSE_JSON" | jq -r '.access_token')"
}

login_via_device() {
    # See https://git.mobilexag.de/prd-serviceplatform/documentation/-/blob/develop/modules/operations-guide/examples/read-token-from-keycloak.sh?ref_type=heads
    # https://datatracker.ietf.org/doc/html/rfc8628#section-3.1
    local device_code user_code verification_uri expires interval expire_seconds error access_token
    local -a request_data

    configure || return $?

    request_data=(
        --data "client_id=$OAUTH2_CLIENT_ID"
        --data "scope=$OAUTH2_SCOPE"
    )

    if [ -n "$OAUTH2_CLIENT_SECRET" ] ; then
        request_data+=( --data "client_secret=$OAUTH2_CLIENT_SECRET" )
    fi
    
    OAUTH2_RESPONSE_JSON="$(
        # Note: Client authentication is enabled in keycloak, so we need to pass the client_secret
        # This is not neccessary for other clients like crossmip, where the client is public
        invoke curl -s -X POST \
            --url "$OAUTH2_DEVICE_AUTHORIZATION_ENDPOINT" \
            --header 'content-type: application/x-www-form-urlencoded' \
            ${request_data[@]}
    )"
    #echo "response_json: $OAUTH2_RESPONSE_JSON" 1>&2

    error="$(echo "$OAUTH2_RESPONSE_JSON" | jq -r .error)"
    if [ "$error" != "null" ]; then
        echo "Error response from keycloak: $(printf "%q" "$error")" 1>&2
        echo "$OAUTH2_RESPONSE_JSON" | jq . 1>&2
        return 1
    fi

    device_code="$(echo "$OAUTH2_RESPONSE_JSON" | jq -r .device_code)"
    user_code="$(echo "$OAUTH2_RESPONSE_JSON" | jq -r .user_code)"
    verification_uri="$(echo "$OAUTH2_RESPONSE_JSON" | jq -r .verification_uri)"
    expires="$(echo "$OAUTH2_RESPONSE_JSON" | jq -r .expires_in)"
    interval="$(echo "$OAUTH2_RESPONSE_JSON" | jq -r .interval)"

    (
        echo "Please:"
        echo "    * open $verification_uri"
        echo "    * enter $user_code and log in"
        open "$verification_uri"
    ) 1>&2

    # Loop until the token is available or the timeout is reached
    expire_seconds=$((SECONDS+expires))
    while [ $SECONDS -lt $expire_seconds ]; do
        sleep "$interval"
        OAUTH2_RESPONSE_JSON="$(
            invoke curl -s -X POST \
                --url "$OAUTH2_TOKEN_ENDPOINT" \
                --header 'content-type: application/x-www-form-urlencoded' \
                --data "client_id=$OAUTH2_CLIENT_ID" \
                --data "client_secret=$OAUTH2_CLIENT_SECRET" \
                --data "device_code=$device_code" \
                --data "grant_type=urn:ietf:params:oauth:grant-type:device_code"
        )"
        OAUTH2_ACCESS_TOKEN="$(echo "$OAUTH2_RESPONSE_JSON" | jq -r .access_token)"
        error="$(echo "$OAUTH2_RESPONSE_JSON" | jq -r .error)"
        if [ "$OAUTH2_ACCESS_TOKEN" != "null" ]; then
            break
        fi
        if [ "$error" != "authorization_pending" ]; then
	        echo "Error response from keycloak: $(printf "%q" "$error")" 1>&2
            echo "$OAUTH2_RESPONSE_JSON" | jq . 1>&2
	        return 1
	    fi
    done
}

login() {
    local mode="${1:-$DEFAULT_LOGIN_MODE}"
    case "$mode" in
        client-credentials)
            login_via_client_credentials || return $?
            ;;
        device)
            login_via_device || return $?
            ;;
        *)
            echo "Error: Unknown login mode $mode!" 1>&2
            return 1
    esac

    if $DEBUG_TOKEN ; then
        echo "$OAUTH2_ACCESS_TOKEN" | jwtutil --decode --header --pp 1>&2
        echo "$OAUTH2_ACCESS_TOKEN" | jwtutil --decode --pp 1>&2
    fi

    case "$OUTPUT_FORMAT" in
        raw) echo "$OAUTH2_ACCESS_TOKEN" ;;
        bash) echo "export OAUTH2_ACCESS_TOKEN=$(printf "%q" "$OAUTH2_ACCESS_TOKEN")" ;;
        json) echo "$OAUTH2_RESPONSE_JSON" ;;
        *) echo "Error: Unknown output format: $OUTPUT_FORMAT" 1>&2; return 1 ;;
    esac
}


################################################################################
# Main, argparsing and commands

cmd_temp() {
    configure_via_oidc
}

cmd_check-token() {
    local -i errors
    if [[ -z "$OAUTH2_ACCESS_TOKEN" ]] ; then
        log 1 "No token set (check environment variable OAUTH2_ACCESS_TOKEN)."
        return 1
        (( errors++ ))
    fi
    if ! verify_token_signature "$OAUTH2_ACCESS_TOKEN" ; then
        log 1 "Token signature is invalid"
        (( errors++ ))
    fi
    if is_token_expired "$OAUTH2_ACCESS_TOKEN" ; then
        log 1 "Token is expired"
        (( errors++ ))
    fi
    log 2 "$errors errors."
    if [[ $errors -gt 0 ]] ; then
        echo "Token not valid (anymore)."
        return 1
    else
        echo "Token is valid."
        return 0
    fi
}

cmd_login() {
    login "$@"
}

cmd_read-token() {
    # See https://prd-serviceplatform.mx.lan/documentation/documentation/operations-guide/troubleshooting-azuread.html
    curl -s -X GET \
	    --url "$KEYCLOAK_READ_TOKEN_ENDPOINT" \
	    --header "Authorization: Bearer $OAUTH2_ACCESS_TOKEN"
}

# Example request to a crossmip rest api (online-search-service)
cmd_curl() {
    # FIXME: Check if OAUTH2_ACCESS_TOKEN is set or expired
    invoke -l 1 curl -H "Authorization: Bearer $OAUTH2_ACCESS_TOKEN" "$@"
}

cmd_help() {
    usage
}

usage() {
    echo "Usage: $0 [global flags...] <command...>"
    echo "Global flags:"
    echo "    -v      Increase verbosity level"
    echo "    -q      Decrease verbosity level"
    echo "    --help  Show usage and exit"
    echo ""
    echo "Available commands:"
    echo "    help    Show usage and exit"
    echo ""
}

main() {
    declare cmd=""
    declare cmderr=0
    while [[ $# -gt 0 ]] ; do
        arg="$1"; shift
        case "$arg" in
            -v) (( VERBOSITY++ )) ;;
            -q) (( VERBOSITY-- )) ;;
            -f|--format|--output-format) OUTPUT_FORMAT="$1"; shift ;;
            --help)
                cmd=help
                break
                ;;
            -*)
                { echo "Unknown flag: $arg"; usage; } 1>&2
                return 1
                ;;
            *)
                cmd="$arg"
                break
                ;;
        esac
    done
    if [[ -z "$cmd" ]] ; then
        usage
    elif [[ $(type -t "cmd_$cmd") == function ]] ; then
        "cmd_$cmd" "$@"
        cmderr="$?"
        if [[ "$cmderr" -ne 0 && "$LAST_COMMAND_EXITCODE" -ne 0 ]] ; then
            report_command_failure 1>&2
            echo "" 1>&2
        fi
        return "$cmderr"
    else
        { echo "Unknown command: $cmd"; usage; } 1>&2
        return 1
    fi
}

main "$@"
