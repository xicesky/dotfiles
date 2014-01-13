#!/bin/bash
#
# Shell function library
#
# Ideas / TODO:
# - Error reporting functions: http://linuxcommand.org/wss0150.php
# - Use bash's "set -u" to check for unset variables

function invoke() {
    $VERBOSE && echo $@
    if $REALLY ; then
        "$@"
    else
        true
    fi
}

function fexists() {
    type -t $1 >/dev/null
}

function checkpipestatus {
    for i in $@; do
        if [[ ( $i > 0 ) ]]; then
            return $i
        fi
    done
    return 0
}

function parts_ending_on() {
    ls $1 | awk 'match($0, /^(.*)'$2'$/, m) { print m[1]; }'
}

function relpath() {
    python -c "import os.path; print os.path.relpath('$1', '${2:-$PWD}')" 
}

function print_shellscript_header() {
    echo "#!/bin/bash"
    echo "# This is a shell include file, no need to run it."
    echo ""
}

function configure() {
    CONFIGFILE="$1"         # Config file is argument #1
    [ -n "$CONFIGFILE" ] || return 1
    # Configuration script on STDIN

    # 1. Create a configuration file if it doesn't exist
    [ -e "$CONFIGFILE" ] || (
        print_shellscript_header
        cat
    ) > "$CONFIGFILE"
   
    # 2. Emit code to load the configuration file
    #echo "source \"$CONFIGFILE\""

    # 3. Emit the remaining configuration on STDIN, if any
    # We need to re-eval the configuration, so any missing variables
    # (e.g. in case of an old config file) get set to useful defaults
    # This has no effect if a configuration file was created in step 1
    # but in exactly this case it is not neccessary.
    #cat
}

