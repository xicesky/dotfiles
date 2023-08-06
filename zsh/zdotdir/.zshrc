#!/usr/bin/zsh
#
# .zshrc - Run on interactive Zsh session.
#

# Temporary, just for timing zsh startup
[[ -z "$ZPROFRC" ]] || echo "$(date +"%T.%N") ENTER \$ZDOTDIR/.zshrc"

# init profiling
[[ -z "$ZPROFRC" ]] || zmodload zsh/zprof
alias zprofrc="ZPROFRC=1 zsh"

# zstyles
if [[ -r $ZDOTDIR/.zstyles ]] ; then
    . $ZDOTDIR/.zstyles
else
    echo "WARNING: Missing $ZDOTDIR/.zstyles"
fi

# See https://github.com/romkatv/powerlevel10k/blob/master/README.md#how-do-i-configure-instant-prompt
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.config/zsh/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -z "$ZPROFRC" && -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# use antidote for plugin management
export ANTIDOTE_HOME=${XDG_CACHE_HOME:=~/.cache}/repos
if [[ ! -d $ANTIDOTE_HOME/mattmc3/antidote ]] ; then
    echo "First time run, cloning https://github.com/mattmc3/antidote ..."
    git clone --depth 1 --quiet https://github.com/mattmc3/antidote $ANTIDOTE_HOME/mattmc3/antidote
fi

source $ANTIDOTE_HOME/mattmc3/antidote/antidote.zsh
antidote load

# prompt
#prompt starship mmc
#prompt p10k pure

# done profiling
[[ -z "$ZPROFRC" ]] || zprof

# cleanup
unset ZPROFRC zplugins

# Note: mingw/msys resets the path in /etc/profile
# so the setting in .zshenv has no effect and we need to update it here
if ismingw || ismsys ; then
    _sky_loadenv
fi

# Temporary, just for timing zsh startup
[[ -z "$ZPROFRC" ]] || echo "$(date +"%T.%N") EXIT  \$ZDOTDIR/.zshrc"

true

# To customize prompt, run `p10k configure` or edit ~/.config/zsh/.p10k.zsh.
[[ ! -f ~/.config/zsh/.p10k.zsh ]] || source ~/.config/zsh/.p10k.zsh
