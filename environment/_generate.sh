#!/bin/bash

SRC_DIR="$(dirname "$0")"
DST="$1"; shift
MY_OSTYPE=$(uname -s)

exec_all() {
    while IFS= read -r -d $'\0' file ; do
        echo "# $(basename "$file")"
        # shellcheck disable=SC1090
        source "$file"
    done < <(
        find "$SRC_DIR" -mindepth 1 -maxdepth 1 -iname "*.sh" -a \( \( -iname "_*" \) -o \( -print0 \) \) | sort -z
    )
}

# FIXME: Isn't /run/lock the new standard? If yes, prefer it over /var/lock!
LOCKDIR="$(readlink -f "/var/lock")"
if [[ ! -w "$LOCKDIR" ]] ; then
    LOCKDIR="$HOME/.var/lock"
    if [[ ! -e "$LOCKDIR" ]] ; then
        mkdir -p "$LOCKDIR" || { echo "Could not mkdir " >&2; exit 1; }
    fi
fi
if [[ $MY_OSTYPE = MINGW* || $MY_OSTYPE = MSYS* ]] ; then
    mkdir -p "$LOCKDIR" || { echo "Could not mkdir " >&2; exit 1; }
fi

LOCKFILE="$LOCKDIR/sky-dotfiles-$(basename "$0")"
LOCKFD=9 #LOCKFD=99 # 99 doesn't work on mingw / msys2
_lock()             { flock "-$1" $LOCKFD; }
_release_lock()     { _lock u; _lock xn && rm -f "$LOCKFILE"; }
_prepare_locking()  { eval "exec $LOCKFD>\"$LOCKFILE\""; trap _release_lock EXIT; }

if [[ -z "$DST" ]] ; then
    exec_all
else
    _prepare_locking
    _lock x || exit 1
    mkdir -p "$(dirname "$DST")"
    exec_all >"$DST"
    _release_lock
fi
