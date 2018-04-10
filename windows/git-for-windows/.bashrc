#!/bin/bash

echo "==============================================================================="
echo "Git Bash"
echo ""

################################################################################
# Fix the path (cygwin needs to go)

NEWPATH=""
SAVEIFS="$IFS"
IFS=:
for P in $PATH; do
    if [[ "$P" == *"cygwin"* ]]; then
        echo "Excluding path element: $P"
    else
        NEWPATH="$NEWPATH:$P"
    fi
    #echo "$P"
done
IFS="$SAVEIFS"
PATH="$NEWPATH"

echo "==============================================================================="
#echo "Bashrc          : `basename "$0"`"
echo "Bashrc          : $BASH_SOURCE"
echo "Path            : $PATH"

