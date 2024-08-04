#!/bin/bash

exec_all() {
    while IFS= read -r -d $'\0' file ; do
        echo "# $(basename "$file")"
        # shellcheck disable=SC1090
        source "$file"
    done < <(
        find "$2" -mindepth 1 -maxdepth 1 -iname "$1" -a \( \( -iname "_*" \) -o \( -iname ".*" \) -o \( -print0 \) \) | sort -z
    )   
}

if [[ -n "$BASH_DOTDIR" && -d "$BASH_DOTDIR" ]]; then
    exec_all "*_rc_*.sh" "$BASH_DOTDIR"
fi
