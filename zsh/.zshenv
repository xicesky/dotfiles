
# Utility functions to detect system type
# grml's zsh setup provides islinux, isdarwin, isfreebsd, ...

GRML_OSTYPE=$(uname -s)

function ismingw() {
    [[ $GRML_OSTYPE = MINGW* ]]
}

function ismsys() {
    [[ $GRML_OSTYPE = MSYS* ]]
}

isdarwin(){
    [[ $OSTYPE == darwin* ]] && return 0
    return 1
}

typeset -U path

# Note: mingw/msys resets the path later, thus it is defined in a separate file
# so we can re-read it later
if ismingw || ismsys ; then
    # echo "Detected mingw/msys: $GRML_OSTYPE"
    # echo "    -> not setting path early"
    :
else
    if [ -r "${ZDOTDIR:-${HOME}}/.zsh.path" ] ; then
        source "${ZDOTDIR:-${HOME}}/.zsh.path"
    else
        typeset -U path
        path=(~/bin ~/.local/bin /usr/local/bin /usr/local/sbin $path)
    fi
fi

# For informing servers about our identity
export REAL_USER=markus

# Default options for less
export PAGER=less
export LESS=RS#.2

