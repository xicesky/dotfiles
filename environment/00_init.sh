#!/bin/bash

echo "# SHELL_TYPE=$SHELL_TYPE"

# System-specific detection functions
MY_OSTYPE=$(uname -s)
echo "export MY_OSTYPE=$(printf "%q" "$MY_OSTYPE")"

case "$MY_OSTYPE" in
    MINGW*) function ismsystem() { true; }; function ismingw() { true; }; function ismsys() { false; }  ;;
    MSYS*)  function ismsystem() { true; }; function ismingw() { false; }; function ismsys() { true; } ;;
    *)      function ismsystem() { false; }; function ismingw() { false; }; function ismsys() { false; }  ;;
esac

if [[ $OSTYPE == darwin* ]] ; then
    function isdarwin() { true; }
else
    function isdarwin() { false; }
fi

if [[ -r /proc/version ]] ; then
    case "$(cat /proc/version)" in
        *-microsoft*-WSL2*)
            function iswsl2() { true; }
            ;;
        *)
            function iswsl2() { false; }
            ;;
    esac
fi

declare -f ismsystem
declare -f ismingw
declare -f ismsys
declare -f isdarwin
declare -f iswsl2

# Shell type
if [ -z "$SHELL_TYPE" ] ; then
    SHELL_TYPE="$(basename "$SHELL")"
fi
echo "SHELL_TYPE=$(printf "%q" "$SHELL_TYPE")"

function regenerate_env() {
    declare gensh
    echo "Generating $XDG_CACHE_HOME/environment/$SHELL_TYPE" 1>&2
    mkdir -p "$XDG_CACHE_HOME/environment"
    gensh="${SKY_DOTFILES:-$HOME/_dotfiles}/environment/_generate.sh"
    # shellcheck disable=SC2097
    SHELL_TYPE=$SHELL_TYPE "$gensh" "$XDG_CACHE_HOME/environment/$SHELL_TYPE"
    # shellcheck disable=SC1090
    . "$XDG_CACHE_HOME/environment/$SHELL_TYPE"
}

function export_variable() {
    local -a exportargs=()
    while [[ $# -gt 0 ]] ; do case "$1" in
        -*) exportargs+=("$1"); shift ;;
        *) break ;;
    esac; done

    local content
    if [[ $# -gt 1 ]] ; then
        content="$2"
    else
        content="${!1}"
    fi

    echo export "${exportargs[@]}" "$1=$(printf "%q" "$content")"
}

declare -f regenerate_env

if [[ "$SHELL_TYPE" = "zsh" ]] ; then
    echo '# Ensure path arrays do not contain duplicates.'
    echo 'typeset -gU fpath path cdpath'

    # shellcheck disable=SC2016
    echo 'path=(~/bin ~/.local/bin /usr/local/bin /usr/local/sbin $path)'

    function append_to_path() {
        echo "path+=( $(printf "%q " "$@"))"
    }

    function prepend_to_path() {
        echo "path=( $(printf "%q " "$@")\$path)"
    }
else
    # FIXME: make sure entries are unique in bash, too

    # shellcheck disable=SC2016
    echo 'PATH=~/bin:~/.local/bin:/usr/local/bin:/usr/local/sbin:$PATH'

    function append_to_path() {
        echo "PATH=\$PATH$(printf ":%q" "$@")"
    }

    function prepend_to_path() {
        echo "PATH=$(printf "%q:" "$@")\$PATH"
    }
fi
