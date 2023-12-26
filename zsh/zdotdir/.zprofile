#!/usr/bin/zsh
#
# .zprofile - Run on login Zsh session.
#

# Temporary, just for timing zsh startup
[[ -z "$ZPROFRC" ]] || echo "$(date +"%T.%N") ENTER \$ZDOTDIR/.zprofile"

# Temporary, just for timing zsh startup
[[ -z "$ZPROFRC" ]] || echo "$(date +"%T.%N") EXIT  \$ZDOTDIR/.zprofile"
