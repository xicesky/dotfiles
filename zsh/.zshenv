typeset -U path
path=(~/bin ~/.local/bin /usr/local/bin /usr/local/sbin $path)

# Check if we can find android sdk or platform tools
if [ -d "/usr/local/share/android-sdk" ] ; then
    export ANDROID_SDK_ROOT="/usr/local/share/android-sdk"
    path=($path "$ANDROID_SDK_ROOT/platform-tools")
elif [[ -d "$HOME/Library/Android/sdk/platform-tools" ]] ; then
    # No? Check if we have platform tools at least
    path=($path "$HOME/Library/Android/sdk/platform-tools")
fi

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

