typeset -U path
path=(~/bin /usr/local/bin $path)

[[ -d "$HOME/Library/Android/sdk/platform-tools" ]] && path=($path "$HOME/Library/Android/sdk/platform-tools")

# MAC specific
# FIXME: Mac already has /etc/zshrc and /etc/zprofile - those mess with our paths
#   So we need a way to load our paths AFTER the zprofile eval.
if [ -x /usr/local/bin/brew ] ; then
    # Mac with homebrew, use GNU stuff when available
    LOC_COREUTILS="$(brew --prefix coreutils)/libexec/gnubin"
    
    # Doesn't work currently, see above
    #echo "PATH=$PATH"
    [[ -d "$LOC_COREUTILS" ]] && {
        path=("$LOC_COREUTILS" $path)
        #echo "PATH=$PATH"
    }

fi

# For informing servers about our identity
export REAL_USER=markus

# Default options for less
export PAGER=less
export LESS=RS#.2

