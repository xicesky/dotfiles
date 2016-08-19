typeset -U path
path=(~/bin /usr/local/bin $path)

[[ -d "$HOME/Library/Android/sdk/platform-tools" ]] && path=($path "$HOME/Library/Android/sdk/platform-tools")

# For informing servers about our identity
export REAL_USER=markus

# Default options for less
export PAGER=less
export LESS=RS#.2

