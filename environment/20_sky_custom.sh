#!/bin/bash

# Set the list of directories that cd searches.
# cdpath=(
#   $XDG_PROJECTS_DIR(N/)
#   $XDG_PROJECTS_DIR/mattmc3(N/)
#   $cdpath
# )


# Custom
# export DOTFILES=$XDG_CONFIG_HOME/dotfiles
# export GNUPGHOME=$XDG_DATA_HOME/gnupg
echo "export REPO_HOME=\$XDG_CACHE_HOME/repos"

# Actually only used by zsh
echo "export ANTIDOTE_HOME=\$REPO_HOME"

# Preferences
cat <<"EOF"
[ -z "$EDITOR" ] || export EDITOR='vim'
[ -z "$VISUAL" ] || export VISUAL='vim'
[ -z "$PAGER" ] || export PAGER='less'
#[ -z "$LESS" ] || export LESS='-g -i -M -R -S -w -z-4'
[ -z "$READNULLCMD" ] || READNULLCMD=$PAGER
EOF
