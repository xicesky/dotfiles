#!/bin/bash

resolve() {
    (
        cd "$1"
        echo "$(readlink -f "$(dirname "$2")")/$(basename "$2")"
    )
}

resolve-symlink() {
    resolve "$(dirname "$1")" "$(readlink "$1")"
}

NO_INITIAL=false
if [[ "$1" = "--no-initial" ]] ; then NO_INITIAL=true; shift; fi

file="$1"
if $NO_INITIAL; then
    [ -h "$file" ] || { exit 1; }
    file="$(resolve-symlink "$file")"
fi

while true; do
    echo -n "$file"
    [ -e "$file" ] || { echo -n " ! Missing"; break; }
    [ -h "$file" ] || { break; }
    echo -n " -> "
    file="$(resolve-symlink "$file")"
done
echo ""
