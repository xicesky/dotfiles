#!/usr/bin/zsh
#
# .zshenv - Zsh environment file, loaded always.
#

# Temporary, just for timing zsh startup
[[ -z "$ZPROFRC" ]] || echo "$(date +"%T.%N") ENTER \$ZDOTDIR/.zshenv"

# Prevent debian's /etc/zshrc from running compinit - it will be run
# in our .zshrc anyway and just degrate startup performance
skip_global_compinit=1

# XDG_CACHE_HOME is required before _sky_loadenv
export XDG_CACHE_HOME=~/.cache

# Shell type
if [ -z "$SHELL_TYPE" ] ; then
    # FIXME: There is probably a faster way than basename
    SHELL_TYPE="$(basename "$SHELL")"
fi

# Load (generated) environment
function _sky_loadenv() {
    if [[ -r "$XDG_CACHE_HOME/environment/$SHELL_TYPE" ]] ; then
        . "$XDG_CACHE_HOME/environment/$SHELL_TYPE"
    else
        # Generate it
        if [[ -x "$HOME/_dotfiles/environment/_generate.sh" ]] ; then
            echo "First time init: Generating $XDG_CACHE_HOME/environment/$SHELL_TYPE" 1>&2
            mkdir -p "$XDG_CACHE_HOME/environment"
            gensh="${SKY_DOTFILES:-$HOME/_dotfiles}/environment/_generate.sh"
            SHELL_TYPE=$SHELL_TYPE "$gensh" "$XDG_CACHE_HOME/environment/$SHELL_TYPE"
            . "$XDG_CACHE_HOME/environment/$SHELL_TYPE"
        fi
    fi
}

# May have to run this again later on some systems (e.g. OSX)
_sky_loadenv

# Temporary, just for timing zsh startup
[[ -z "$ZPROFRC" ]] || echo "$(date +"%T.%N") EXIT  \$ZDOTDIR/.zshenv"
