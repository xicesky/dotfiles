#!/bin/bash
# This is an included file, call with "source ..." !

# Launches ssh-pageant on cygwin / msys2
# VERY VERY OLD AND DEPRECATED
# I don't even know if this works anymore

#set -e
#set -x
shopt -s nocasematch

SOCKET="/tmp/.ssh-pageant-${USER}"

sp() {
    /usr/bin/ssh-pageant -ra "$SOCKET"
}

FN=$(mktemp)

# Execute the command to check
ERR=$(sp 2>&1 1>"$FN") || {
    MY_ERRNO="$?"

    # Check for the stupid "connect: No error" fail
    if [[ "$ERR" =~ "connect: no error" ]] ; then
        #echo "$ERR" 1>&2
        echo "Removing dangling socket $SOCKET" 1>&2
        rm "$SOCKET"
        sp >"$FN" || {
            rm "$FN"
            exit $?
        }
    else
        echo "$ERR" 1>&2
        rm "$FN"
        exit $MY_ERRNO
    fi
}

cat "$FN"
rm "$FN"
