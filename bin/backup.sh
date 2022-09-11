#!/bin/bash

VERBOSITY="${VERBOSITY:-2}"
NO_ACT="${NO_ACT:-false}"
REMOVE=false

if [[ "$SCRIPT_DIR" = "" ]] ; then
    SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
fi
if [[ ! -x "$SCRIPT_DIR/system-detect.sh" ]] ; then
    echo "Error: could not find script directory at $SCRIPT_DIR" 1>&2
    exit 1
fi
# case "$("$SCRIPT_DIR/system-detect.sh")" in
#     MINGW64*)
#         ;;
# esac

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

invoke() {
    LAST_COMMAND=("$@")
    log -p "" 2 "$(printf "%q " "$@")"
    $NO_ACT || {
        LAST_COMMAND_EXITCODE=0
        "$@" || LAST_COMMAND_EXITCODE="$?"
        return $LAST_COMMAND_EXITCODE
    }
}

report_command_failure() {
    if [[ "$LAST_COMMAND_EXITCODE" -ne 0 ]] ; then
        log 1 ""
        log 1 "Last command executed:"
        log 1 "    $(printf "%q " "${LAST_COMMAND[@]}")"
        log 1 "Returned exit code ${LAST_COMMAND_EXITCODE}"
    fi
}

canonical-path() {
    if [[ -d "$1" ]] ; then
        # If it's a directory, just cd and pwd
        ( cd "$1" && pwd; )
    else
        # For files just canonicalize the dirname
        echo "$(canonical-path "$(dirname "$1")")/$(basename "$1")"
    fi
}

backup() {
    src="$(canonical-path "$1")"; shift
    [[ "$src" != /* ]] && { echo "Error: source path must be absolute: $src" 1>&2; return 1; }

    target="$(basename "$src").7z"
    targetdir="$BUPDIR/$(dirname "$src")"
    is_archive=false
    if [[ "$src" = *.7z || "$src" = *.zip || "$src" = *.tar.* ]] ; then
        is_archive=true
        target="$(basename "$src")"
    fi

    invoke mkdir -p "$targetdir" || return 1
    if $is_archive ; then
        invoke cp "$src" "$targetdir/$target" || return 1
    else
        invoke 7z a "$targetdir/$target" "$src" || return 1
    fi
    if $REMOVE ; then
        invoke rm -rf "$src" || return 1
    fi
}

help() {
    log 0 ""
    log 0 "$THIS_SCRIPT_NAME - simple backup script v$THIS_SCRIPT_VERSION"
    log 0 ""
    log 0 "Usage:"
    logf 0 "    %s [options] <file>\n" "$THIS_SCRIPT_NAME"
    log 0 ""
}

main() {
    BUPDIR="${BUPDIR:-/e/Backup/2022-09-10-Backup-MobileX-Notebook}"
    if [[ ! -d "$BUPDIR" ]] ; then
        echo "Error: could not find backup directory at $BUPDIR" 1>&2
        exit 1
    fi

    declare -a sources=()

    # Parse arguments
    while [[ $# -gt 0 ]] ; do
        arg="$1"; shift
        case "$arg" in
        --help|help)
            help "$@"
            return 0
            ;;
        --version|version)
            # Display version and exit
            echo "$THIS_SCRIPT_VERSION"
            return 0
            ;;
        -v|--verbose)
            (( VERBOSITY++ ))
            ;;
        -q|--quiet)
            (( VERBOSITY-- ))
            ;;
        -x|--act)
            NO_ACT=false
            ;;
        -n|--no-act)
            NO_ACT=true
            ;;
        --rm)
            REMOVE=true
            ;;
        -*)
            error 1 "Unknown option: $arg" || true
            echo "    ... here's the help:" 1>&2
            help
            return 1
            ;;
        *)
            sources+=( "$arg" )
            ;;
        esac
    done

    for i in "${sources[@]}" ; do
        backup "$i" || return $?
    done
}

main "$@" || {
    report_command_failure
    exit 1
}
