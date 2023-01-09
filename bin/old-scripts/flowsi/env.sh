#!/bin/bash
#set -x
set -e

################################################################################################################################################################
# TODO:
#   Fix build, run, update targets
#   Forward unknown commands directly to flowsi.sh
#

# OS Detection
OSX=false
WINDOWS=false
#LINUX is assumed by default
READLINK="`which readlink`"

case "`uname | tr '[:upper:]' '[:lower:]'`" in
    darwin)
        OSX=true
        READLINK="`which greadlink`"    # FIXME: brew install coreutils
        ;;
    mingw*)
        WINDOWS=true
        ;;
    *)
        # Assume posix / linux
        :
        ;;
esac

# Capture script properties before we mess anything up
THIS_SCRIPT="`$READLINK -f "$0"`"
THIS_SCRIPT_NAME="`basename "$THIS_SCRIPT"`"
THIS_SCRIPT_DIR="`dirname "$THIS_SCRIPT"`"
THIS_RUN_DIR="`pwd`"

################################################################################################################################################################
# Settings

# Project
PROJECT_NAME="flowsi"
MAIN_DIR="$THIS_SCRIPT_DIR"     # Paths are usually relative to this

# Local dir
LOCAL_DIR="$MAIN_DIR/_local"
mkdir -p "$LOCAL_DIR"

# Where to store environment settings
ENVIRONMENT_FILE="$LOCAL_DIR/.projectrc"  # This has to be an absolute path

# Tools (defaults)
TOOL_WHICH=/usr/bin/which
TOOL_SHELL="$SHELL"
TOOL_SHELL_BEHAVIOUR="`basename $SHELL`"    # bash or zsh supported

# Settings can be overridden locally
LOCAL_SETTINGS_FILE="$LOCAL_DIR/.project.sh.settings"
[ -e "$LOCAL_SETTINGS_FILE" ] || echo "" >"$LOCAL_SETTINGS_FILE"
. "$LOCAL_SETTINGS_FILE"

################################################################################################################################################################
# Utility functions

invoke() {
    echo "$@"
    "$@"
}

invoke_devnull() {
    echo "$@"
    "$@" >/dev/null
}

complain() {
    CODE="$1"
    shift
    printf "$@" 1>&2
    exit $CODE
}

# Windows path conversion - don't do the work when not on windows
if $WINDOWS ; then
    TOOL_CYGPATH="$($TOOL_WHICH cygpath || echo "")"
    #echo "TOOL_CYGPATH: $TOOL_CYGPATH"
    
    if [ -x "$TOOL_CYGPATH" ] ; then
        convpath() {
            cygpath -ua "$@"
        }
    else
        convpath() {
            sed -e 's/\\/\//g' -e 's/\([a-zA-Z]\):/\/\1/g'
        }
    fi
    PATH_PROGRAMFILES="$(convpath "$PROGRAMFILES")"
    echo "PATH_PROGRAMFILES: $PATH_PROGRAMFILES"
else
    convpath() { cat; }
fi

################################################################################################################################################################
# Tool invocation

TOOL_SEARCH_PATH="~/bin:/bin:/sbin:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin"
if $WINDOWS ; then
    TOOL_SEARCH_PATH="$TOOL_SEARCH_PATH:/c/Program Files/Git"   # FIXME use $EXEPATH and or $PROGRAMFILES
fi
TOOL_SEARCH_PATH="$TOOL_SEARCH_PATH:$PATH"

tool_search() {
    #PATH="$TOOL_SEARCH_PATH" $TOOL_WHICH "$@" || echo ""
    local i s
    for i in "$@" ; do
        if s="$(PATH="$TOOL_SEARCH_PATH" $TOOL_WHICH "$i" 2>/dev/null)" ; then
            echo "$s"
            return 0
        fi
    done
    echo ""
}

[ -n "$TOOL_MINTTY" ] || TOOL_MINTTY="$(tool_search mintty)"

# TODO node, npm, pm2

tool_list() {
    printf "%-20s: %s\n" "TOOL_SHELL" "$TOOL_SHELL"
    printf "%-20s: %s\n" "TOOL_MINTTY" "$TOOL_MINTTY"
    echo ""

    # TODO node, npm, pm2 version

    # VERSION_PYTHON3="$($TOOL_PYTHON3 --version 2>&1 | sed -n -e 's/^Python \([^ ]\+\).*$/\1/p')"
    # printf "%-20s: %s\n" "VERSION_PYTHON3" "$VERSION_PYTHON3"
    # printf "%-20s: %s\n" "PYTHON3_SCRIPTS_DIR" "$PYTHON3_SCRIPTS_DIR"

    # VERSION_PIP3="$($TOOL_PIP3 --version 2>&1 | sed -n -e 's/^pip \([^ ]\+\).*$/\1/p')"
    # printf "%-20s: %s\n" "VERSION_PIP3" "$VERSION_PIP3"
}

tool_shell_env() {
    local ENVFILE="$1"
    shift
    #local ENVCMD="$@"
    local INITFLAG=""

    case $TOOL_SHELL_BEHAVIOUR in
        bash)
            INITFLAG="--init-file"
            ;;
        zsh)
            #INITFLAG="--rcs"
            # HACK
            #(
            #    set +e
            #    source $ENVFILE
            #    [ -z "$1" ] || "$@"
            #    $TOOL_SHELL --no-rcs
            #)

            # This works "somewhat"... Include user's settings too.
            # http://zsh.sourceforge.net/Intro/intro_3.html
            # http://zsh.sourceforge.net/Guide/zshguide02.html
            local ZDIR="`dirname "$ENVFILE"`"
            [ -e "$ZDIR/.zshrc" ] || ln -s "$ENVFILE" "$ZDIR/.zshrc"
            ZDOTDIR="$ZDIR" zsh # --no-global-rcs

            return 0
            ;;
        *)
            complain 01 "Unsupported shell type: $TOOL_SHELL_BEHAVIOUR - $TOOL_SHELL"
            ;;
    esac

    if [ "$1" == "" ] ; then
        "$TOOL_SHELL" $INITFLAG "$ENVFILE"
    else
        # FIXME: We can only hope the args don't contain spaces here...
        #bash --init-file <(echo set -x\; . \""$ENVIRONMENT_FILE"\"\; "$@")
        "$TOOL_SHELL" $INITFLAG <(echo . \""$ENVFILE"\"\; "$@")
    fi
}

################################################################################################################################################################
# Environment stuff

env_run() {
    # FIXME: alias doesn't list aliases in a shell script! (this seems odd and buggy)
    alias >"$ENVIRONMENT_FILE"
    PATH_TO_PHP="`dirname "$TOOL_PHP"`"
    PATH_TO_COMPOSER="`dirname "$TOOL_COMPOSER"`"
    cat >>"$ENVIRONMENT_FILE" <<EOF
[ -f "$LOCAL_DIR/.projectrc.local" ] && . "$LOCAL_DIR/.projectrc.local"
alias p="$THIS_SCRIPT"
export TITLEPREFIX="$PROJECT_NAME"
export PS_HINT="$PROJECT_NAME"
#PS1='\[\033]0;\$TITLEPREFIX:\${PWD//[^[:ascii:]]/?}\007\]\n\[\033[32m\]\u@\h \[\033[35m\]\$PS_HINT \[\033[33m\]\w\[\033[36m\]\`__git_ps1\`\[\033[0m\]\n\$ '
PATH="\$PATH:$PATH_TO_PHP:$PATH_TO_COMPOSER"
echo -e "\033[32m"
echo "==============================================================================="
echo "  Loaded $PROJECT_NAME environment. Have fun!"
#echo "      MY_SPECIAL_VARIABLE=\$MY_SPECIAL_VARIABLE"
echo -e "\033[0m"
# Too slow on startup
#echo ""
#p config
EOF
    tool_shell_env "$ENVIRONMENT_FILE" "$@"
}

################################################################################################################################################################
# Build

build() {
    # Not sure yet
    :
}

################################################################################################################################################################
# Main

help() {
    echo   "Usage: $THIS_SCRIPT_NAME <command> ..."
    echo   ""
    #echo   "For details, try $THIS_SCRIPT_NAME help <command>"
    echo   "Available commands:"
    echo   "    help                - show this help"
    echo   ""
    echo   "    config              - show configuration"
    echo   ""
    echo   "    env                 - run bash project environment"
}

main() {

    COMMAND="$1"
    shift || true

    if [ -z "$COMMAND" ] ; then COMMAND="env"; fi

    case "$COMMAND" in
        env)
            env_run "$@"
            ;;

        ################################################################################
        # Building, running & dependency management

        build)
            build
            ;;

        run)
            # TODO: run composer install when there were changes to composer.json
            build
            tool_php -f main2.php -- "$@"
            ;;

        update)
            # https://getcomposer.org/doc/01-basic-usage.md
            tool_composer update
            ;;

        ################################################################################
        # Help / fail

        config)
            tool_list
            ;;



        help)
            help
            ;;

        *)
            help
            echo ""
            complain 01 "Unknown command: $1\n"
            ;;
    esac

}

################################################################################################################################################################

# Just run it already
main "$@"
