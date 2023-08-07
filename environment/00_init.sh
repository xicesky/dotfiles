#!/bin/bash

echo "# SHELL_TYPE=$SHELL_TYPE"

# System-specific detection functions
MY_OSTYPE=$(uname -s)
echo "export MY_OSTYPE=$(printf "%q" "$MY_OSTYPE")"

function ismingw() {
    [[ $MY_OSTYPE = MINGW* ]]
}

function ismsys() {
    [[ $MY_OSTYPE = MSYS* ]]
}

function isdarwin() {
    [[ $OSTYPE == darwin* ]]
}

function iswsl2() {
    [[ -r /proc/version && "$(cat /proc/version)" = Linux\ *-microsoft*-WSL2\ * ]]
}

declare -f ismingw
declare -f ismsys
declare -f isdarwin

# Shell type
if [ -z "$SHELL_TYPE" ] ; then
    SHELL_TYPE="$(basename "$SHELL")"
fi

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
