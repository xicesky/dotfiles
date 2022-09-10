#!/bin/bash

VERBOSITY="${VERBOSITY:-2}"
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

main() {
    SRC="$1"; shift
    BUPDIR="${BUPDIR:-/e/Backup/2022-09-10-Backup-MobileX-Notebook}"
    target="$(basename "$SRC").7z"
    targetdir="$(dirname "$SRC")"

    invoke mkdir -p "$BUPDIR/$targetdir" || return 1
    invoke 7z a "$BUPDIR/$targetdir/$target" "$SRC" || return 1
    invoke rm -rf "$SRC"
}

main "$@" || {
    report_command_failure
    exit 1
}
