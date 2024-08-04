#!/bin/bash

# Save current PATH for later (mostly for mingw)
export SKY_ORIGINAL_PATH="$PATH"

# MinGW / MSYS2
if [[ ! -r /etc/msystem ]] ; then
    function ismsystem() { false; }
    function ismingw() { false; }
    function ismsys() { false; }
else
    function is_msystem() { true; }
    function ismingw() { [[ "$MSYSTEM" = MINGW* ]]; }
    function ismsys() { [[ "$MSYSTEM" = MSYS* ]]; }
    emulate sh -c 'source /etc/msystem'
    # Hard reset the possibly broken PATH for now (avoid e.g. using "sort" and "find" from windows)
    PATH="/usr/local/bin:/usr/bin:/bin"
fi

# XDG_CACHE_HOME is required before _sky_loadenv
export XDG_CACHE_HOME=~/.cache

# Shell type
export SHELL_TYPE=bash
export SKY_DOTFILES="${SKY_DOTFILES:-"$HOME/_dotfiles"}"
export SKY_ENVIRONMENT_FILE="${SKY_ENVIRONMENT_FILE:-$XDG_CACHE_HOME/environment/$SHELL_TYPE}"

# Load (generated) environment
function _sky_loadenv() {
    SKY_ENVIRONMENT_FILE="${SKY_ENVIRONMENT_FILE:-$XDG_CACHE_HOME/environment/$SHELL_TYPE}"
    if [[ ! -r "$SKY_ENVIRONMENT_FILE" ]] ; then
        # Generate it
        declare gensh="${SKY_DOTFILES:-$HOME/_dotfiles}/environment/_generate.sh"
        if [[ -x "$gensh" ]] ; then
            echo "$(date +"%T.%N") NOTE  First time init: Generating $SKY_ENVIRONMENT_FILE" 1>&2
            "$gensh" "$SKY_ENVIRONMENT_FILE"
        fi
    fi
    if [[ -r "$SKY_ENVIRONMENT_FILE" ]] ; then
        source "$SKY_ENVIRONMENT_FILE"
    fi
}

# May have to run this again later on some systems (e.g. OSX, mingw, msys2)
_sky_loadenv
