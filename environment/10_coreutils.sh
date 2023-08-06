#!/bin/bash

# MAC specific note:
# FIXME: Mac already has /etc/zshrc and /etc/zprofile - those mess with our paths
#   So we need a way to load our paths AFTER the zprofile eval.

if [ -x /usr/local/bin/brew ] ; then
    # Mac with homebrew, use GNU stuff when available
    # shellcheck disable=SC2016
    LOC_COREUTILS="$(brew --prefix coreutils)/libexec/gnubin"
    
    if [[ -d "$LOC_COREUTILS" ]] ; then
        prepend_to_path "$LOC_COREUTILS"
    fi
fi

# Rely on GNU coreutils sort for sorting version numbers
# TODO: Maybe alias all coreutils if installed via homebrew?
SORT="sort"
FIND="find"
if isdarwin; then
    [ -x "$(which gsort)" ] && SORT=gsort
    [ -x "$(which gfind)" ] && FIND=gfind
fi
echo "SORT=$SORT"
echo "FIND=$FIND"
