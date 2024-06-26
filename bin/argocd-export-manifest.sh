#!/bin/bash
# Tool to export argocd application manifests

################################################################################
# Verbosity, command logging

# Verbosity level, 0 is quiet, 1 is normal, 2 prints commands
VERBOSITY="${VERBOSITY:-1}"

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
    while [[ $# -gt 0 ]] ; do
        case "$1" in
            "-o")   shift; redir="$1"; shift ;;
            -*)     echo "invoke: Unknown flag: $arg" 1>&2; return 1 ;;
            *)      break ;;
        esac
    done
    LAST_COMMAND=("$@")
    log -p "" 2 "$(printf "%q " "$@")${redir:+ >$redir}"
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
# ArgoCD export

ARGOCD_NAMESPACE="${ARGOCD_NAMESPACE:-argocd}"
OUTPUT_FORMAT="${OUTPUT_FORMAT:-yaml}"
OUTPUT_DIRECTORY="${OUTPUT_DIRECTORY:-.}"

json_to_output_format() {
    case "$OUTPUT_FORMAT" in
        yaml) yq -p json -o yaml ;;
        json) jq '.' ;;
        *) echo "Error: Unknown output format: $OUTPUT_FORMAT" 1>&2; return 1 ;;
    esac
}

write_file_in_output_format() {
    declare file_basename="$1"; shift
    filename="$OUTPUT_DIRECTORY/$file_basename.$OUTPUT_FORMAT"
    #log 2 "Writing to file: $filename"
    invoke -o "$filename" cat
}

list_apps() {
    # This doesn't list one app per line :/
    #kubectl get -n "$ARGOCD_NAMESPACE" Application -o jsonpath='{.items[*].metadata.name}'
    kubectl get -n "$ARGOCD_NAMESPACE" Application -o json | jq -r '.items[].metadata.name'
}

cmd_list() {
    list_apps
}

# List all applications in the argocd namespace in Markdown format
cmd_mdlist() {
    {   echo "name|namespace|repoURL|chart|revision|targetRevision|"
        echo "---|---|---|---|---|---|"
        kubectl get -n argocd Application -o json \
            | jq -r '.items[] | [
                .metadata.name,
                .spec.destination.namespace,
                .spec.source.repoURL,
                .spec.source.chart,
                .status.sync.revision,
                .spec.source.targetRevision
                ] | join("|")' \
            | sed -e 's/$/|/'
    } | column -t -s'|' -o' | ' | sed -e 's/^/| /'
}

cmd_export() {
    kubectl get -n "$ARGOCD_NAMESPACE" Application "$1" -o json \
        | jq 'del(.status) | .metadata |= with_entries(select(.key == "name" or .key == "namespace"))' \
        | json_to_output_format
}

cmd_export-all() {
    list_apps | while read -r app ; do
        cmd_export "$app" | write_file_in_output_format "$app"
    done
}

################################################################################
# Main, argparsing and commands

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
    echo "    mdlist  List all applications in the argocd namespace in Markdown format"
    echo "    export  Print a single application manifest by name"
    echo "            Usage: $0 export <app-name>"
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
            --no-act) NO_ACT=true ;;
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
