#!/bin/bash
# OAuth2 client in bash, requires a bunch of utilities:
#   - The accompanying jwtutil script
#   - Which in turn needs basenc from coreutils >= 8.31
#   - ... and openssl for signing JWTs
#   - jq for JSON parsing
#   - curl for HTTP requests
# Currently only supports the client credentials flow

################################################################################
# Verbosity, command logging

# Verbosity level, 0 is quiet, 1 is normal, 2 prints commands
VERBOSITY="${VERBOSITY:-1}"
DEBUG_TOKEN=true

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
# Main, argparsing and commands

# service-account-curl-cli
# TODO: Fetch info from .well-known/openid-configuration
# curl "https://idp.kyma-dev.mobilex-serviceplatform.com/auth/realms/ProductDevelopment/.well-known/openid-configuration" | jq .
OAUTH2_CLIENT_ID="${OAUTH2_CLIENT_ID:-curl-cli}"
OAUTH2_CLIENT_SECRET="$OAUTH2_CLIENT_SECRET"
OAUTH2_SCOPE="${OAUTH2_SCOPE:-openid profile}"
OAUTH2_TOKEN_ENDPOINT="${OAUTH2_ENDPOINT:-"https://idp.kyma-dev.mobilex-serviceplatform.com/auth/realms/customer-687399110/protocol/openid-connect/token"}"
OAUTH2_DEVICE_ENDPOINT="${OAUTH2_DEVICE_ENDPOINT:-"https://idp.kyma-dev.mobilex-serviceplatform.com/auth/realms/customer-687399110/protocol/openid-connect/auth/device"}"
OAUTH2_AUDIENCE="${OAUTH2_AUDIENCE:-mip-server}"
OAUTH2_ACCESS_TOKEN="$OAUTH2_ACCESS_TOKEN"
KEYCLOAK_READ_TOKEN_ENDPOINT='https://idp.serviceplatform.eu/auth/realms/customer-687399110/broker/oidc/token'

OUTPUT_FORMAT="bash"

cmd_login-client-credentials() {
    declare response_json access_token
    if [[ -z "$OAUTH2_CLIENT_SECRET" ]] ; then
        echo "Error: OAUTH2_CLIENT_SECRET is not set" 1>&2
        return 1
    fi

    # FIXME: Handle HTTP errors
    response_json="$(
        invoke curl -s -X POST \
            --url "${OAUTH2_TOKEN_ENDPOINT}" \
            --header 'Content-Type: application/x-www-form-urlencoded' \
            --data 'grant_type=client_credentials' \
            --data "client_id=$OAUTH2_CLIENT_ID" \
            --data "client_secret=$OAUTH2_CLIENT_SECRET" \
            --data "audience=$OAUTH2_AUDIENCE"
    )"

    access_token="$(echo "$response_json" | jq -r '.access_token')"
    if $DEBUG_TOKEN ; then
        echo "$access_token" | jwtutil --decode --header --pp 1>&2
        echo "$access_token" | jwtutil --decode --pp 1>&2
    fi
    case "$OUTPUT_FORMAT" in
        raw) echo "$access_token" ;;
        bash) echo "export OAUTH2_ACCESS_TOKEN=$(printf "%q" "$access_token")" ;;
        json) echo "$response_json" ;;
        *) echo "Error: Unknown output format: $OUTPUT_FORMAT" 1>&2; return 1 ;;
    esac
}

cmd_login-device() {
    # See https://git.mobilexag.de/prd-serviceplatform/documentation/-/blob/develop/modules/operations-guide/examples/read-token-from-keycloak.sh?ref_type=heads
    # https://datatracker.ietf.org/doc/html/rfc8628#section-3.1
    # TODO: Not tested yet!
    declare response_json device_code user_code verification_uri expires interval expire_seconds error access_token
    
    response_json="$(
        # Note: Client authentication is enabled in keycloak, so we need to pass the client_secret
        # This is not neccessary for other clients like crossmip, where the client is public
        invoke curl -s -X POST \
            --url "$OAUTH2_DEVICE_ENDPOINT" \
            --header 'content-type: application/x-www-form-urlencoded' \
            --data "client_id=$OAUTH2_CLIENT_ID" \
            --data "client_secret=$OAUTH2_CLIENT_SECRET" \
            --data "scope=$OAUTH2_SCOPE"
    )"
    echo "response_json: $response_json" 1>&2

    error="$(echo "$response_json" | jq -r .error)"
    if [ "$error" != "null" ]; then
        echo "Error response from keycloak: $(printf "%q" "$error")" 1>&2
        echo "$response_json" | jq . 1>&2
        return 1
    fi

    device_code="$(echo "$response_json" | jq -r .device_code)"
    user_code="$(echo "$response_json" | jq -r .user_code)"
    verification_uri="$(echo "$response_json" | jq -r .verification_uri)"
    expires="$(echo "$response_json" | jq -r .expires_in)"
    interval="$(echo "$response_json" | jq -r .interval)"

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
        response_json="$(
            invoke curl -s -X POST \
                --url "$OAUTH2_TOKEN_ENDPOINT" \
                --header 'content-type: application/x-www-form-urlencoded' \
                --data "client_id=$OAUTH2_CLIENT_ID" \
                --data "client_secret=$OAUTH2_CLIENT_SECRET" \
                --data "device_code=$device_code" \
                --data "grant_type=urn:ietf:params:oauth:grant-type:device_code"
        )"
        access_token="$(echo "$response_json" | jq -r .access_token)"
        error="$(echo "$response_json" | jq -r .error)"
        if [ "$access_token" != "null" ]; then
            break
        fi
        if [ "$error" != "authorization_pending" ]; then
	        echo "Error response from keycloak: $(printf "%q" "$error")" 1>&2
            echo "$response_json" | jq . 1>&2
	        return 1
	    fi
    done
    
    if $DEBUG_TOKEN ; then
        echo "$access_token" | jwtutil --decode --header --pp 1>&2
        echo "$access_token" | jwtutil --decode --pp 1>&2
    fi
    case "$OUTPUT_FORMAT" in
        raw) echo "$access_token" ;;
        bash) echo "export OAUTH2_ACCESS_TOKEN=$(printf "%q" "$access_token")" ;;
        json) echo "$response_json" ;;
        *) echo "Error: Unknown output format: $OUTPUT_FORMAT" 1>&2; return 1 ;;
    esac
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

_graphql_query() {
    cat <<'EOF'
query installationsByAddressStreetFragment {
  installationsByFragments(nameFragment: "bay", zipFragment: "81", streetFragment: "Schön") {
    id,
    displayIdJson{jsonString},
    shortTextJson{jsonString},
    address {id,streetJson{jsonString},streetNumberJson{jsonString},zipJson{jsonString},cityJson{jsonString}},
    contact {
      id,
      firstNameJson{jsonString},
      lastNameJson{jsonString},
      contactComms{
        type,
        position,
        valueJson{jsonString},
      }
    },
  }
}
EOF
}

_graphql_query2() {
    cat <<'EOF'
query contactAddressByFragments {
  contactAddressByFragments(nameFragment: "dummy", zipFragment: "81543", streetFragment: "Schön") {
    id, externalId,
    address {id,externalId,streetJson{jsonString},streetNumberJson{jsonString},zipJson{jsonString},cityJson{jsonString}},
    contact {
      id, externalId,
      firstNameJson{jsonString},
      lastNameJson{jsonString},
      contactComms{
        type,
        position,
        valueJson{jsonString},
      },
      installations {
        id, externalId,
        shortTextJson{jsonString},
      }
    },
  }
}
EOF
}

_graphql_request() {
    _graphql_query | jq --raw-input --slurp '{"query":.}'
}

# Example request to a crossmip rest api (online-search-service)
cmd_options-request() {
    #declare target_url="${1:-"https://online-search.kyma-dev.mobilex-serviceplatform.com/graphql"}"
    declare target_url="${1:-"https://customer-687399110-mip.kyma-dev.mobilex-serviceplatform.com/sync-api/3.0/tenants/1/online-search/graphql"}"
    _graphql_request | invoke -l 1 curl -v -X OPTIONS "$target_url" \
        -H "Origin: https://some-custom-origin.com" \
        -H "Authorization: Bearer $OAUTH2_ACCESS_TOKEN" \
        -H "Content-Type: application/json" \
        --data-binary @-
}

# Example request to a crossmip rest api (online-search-service)
cmd_example-request() {
    #declare target_url="${1:-"https://online-search.kyma-dev.mobilex-serviceplatform.com/graphql"}"
    declare target_url="${1:-"https://customer-687399110-mip.kyma-dev.mobilex-serviceplatform.com/sync-api/3.0/tenants/1/online-search/graphql"}"
    _graphql_request | invoke -l 1 curl -v -X POST "$target_url" \
        -H "Origin: https://6546848" \
        -H "Authorization: Bearer $OAUTH2_ACCESS_TOKEN" \
        -H "Content-Type: application/json" \
        --data-binary @-
}

cmd_get-graphql-schema() {
    #declare target_url="${1:-"https://online-search.kyma-dev.mobilex-serviceplatform.com/graphql/schema.graphql"}"
    declare target_url="${1:-"https://customer-687399110-mip.kyma-dev.mobilex-serviceplatform.com/sync-api/3.0/tenants/1/online-search/graphql/schema.graphql"}"
    invoke -l 1 curl -v -X GET "$target_url" \
        -H "Origin: https://some-custom-origin.com" \
        -H "Authorization: Bearer $OAUTH2_ACCESS_TOKEN"
}

cmd_xx() {
    _graphql_request
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
