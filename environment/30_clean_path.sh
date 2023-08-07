#!/bin/bash

if [[ "$SHELL_TYPE" = "zsh" ]] ; then
    if iswsl2 ; then
        cat <<"EOF"
# On windows wsl2 eliminate certain really bad path entries
if [[ -r /proc/version && "$(cat /proc/version)" = Linux\ *-microsoft*-WSL2\ * ]] ; then
    declare -a mu=()
    
    for i in "${path[@]}" ; do
        if echo "$i" | grep -qiPe "(^/mnt/.*(mingw64|msys64|program[^/]*/git|python|nodejs|nvm|AppData/Roaming/npm))" ; then
            continue;
        else
            mu+=("$i")
        fi
    done
    path=("${mu[@]}")
    unset mu
fi
EOF
    elif ismsystem ; then
        cat <<"EOF"
# Append original path entries on mingw / msys
# (Akin to what /etc/profile does)
# SKY_ORIGINAL_PATH is set in .zshenv
if [[ -n "$SKY_ORIGINAL_PATH" ]] ; then
    typeset -gU sky_original_path
    sky_original_path=("${(@s/:/)SKY_ORIGINAL_PATH}")
    path=("${path[@]}" "${sky_original_path[@]}")
fi
EOF
    fi

else
    # FIXME: Port to bash
    true
fi
