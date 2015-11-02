typeset -U path
path=(~/bin /usr/local/bin $path)

# For informing servers about our identity
export REAL_USER=markus

# Default options for less
export PAGER=less
export LESS=RS#.2

