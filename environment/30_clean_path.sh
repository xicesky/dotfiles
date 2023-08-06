#!/bin/bash

if [[ "$SHELL_TYPE" = "zsh" ]] ; then
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

else
    # FIXME: Port to bash
    true
fi
