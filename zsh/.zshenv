#!/usr/bin/zsh
#
# .zshenv - Zsh environment file, loaded always.
# This is acutally just a dummy that resides in your $HOME and forwards
# everything to .config/zsh/*
#

# Enable profiling
# ZPROFRC=1

# Just for timing zsh startup
[[ -z "$ZPROFRC" ]] || echo "$(date +"%T.%N") ENTER ~/.zshenv"

export ZDOTDIR=~/.config/zsh
. "$ZDOTDIR/.zshenv"

# Just for timing zsh startup
[[ -z "$ZPROFRC" ]] || echo "$(date +"%T.%N") EXIT  ~/.zshenv"
