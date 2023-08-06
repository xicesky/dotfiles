#!/bin/bash

SRC_DIR="$(dirname "$0")"
DST="$1"; shift

exec_all() {
    while IFS= read -r -d $'\0' file ; do
        echo "# $(basename "$file")"
        . "$file"
    done < <(
        find "$SRC_DIR" -mindepth 1 -maxdepth 1 \( -iname "_*" \) -o \( -print0 \) | sort -z
    )
}

LOCKFILE="/var/lock/sky-dotfiles-$(basename $0)"
LOCKFD=99
_lock()             { flock "-$1" $LOCKFD; }
_release_lock()     { _lock u; _lock xn && rm -f "$LOCKFILE"; }
_prepare_locking()  { eval "exec $LOCKFD>\"$LOCKFILE\""; trap _release_lock EXIT; }

if [[ -z "$DST" ]] ; then
    exec_all
else
    _prepare_locking
    _lock x || exit 1
    exec_all >"$DST"
    _release_lock
fi
