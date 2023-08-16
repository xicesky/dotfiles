#!/bin/bash

# FIXME: Originally in .zprofile -- why?
# Activate homebrew if installed
if [[ -d /home/linuxbrew/.linuxbrew/bin ]] ; then
    # TODO: Use `brew shellenv` instead, but convert to shell function calls ...?
    cat <<"EOF"
export HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew"
export HOMEBREW_CELLAR="/home/linuxbrew/.linuxbrew/Cellar"
export HOMEBREW_REPOSITORY="/home/linuxbrew/.linuxbrew/Homebrew"
export MANPATH="/home/linuxbrew/.linuxbrew/share/man${MANPATH+:$MANPATH}:"
export INFOPATH="/home/linuxbrew/.linuxbrew/share/info:${INFOPATH:-}"
EOF
    append_to_path "/home/linuxbrew/.linuxbrew/bin"
    append_to_path "/home/linuxbrew/.linuxbrew/sbin"
fi
