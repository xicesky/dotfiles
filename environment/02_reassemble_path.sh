#!/bin/bash

# System-wide configuration often adds unwanted stuff in front of our path
# fix it by building a map of path entries

if [[ "$SHELL_TYPE" = "zsh" ]] ; then
    cat <<"EOF"

    # SKY_ORIGINAL_PATH is usually set in .zshenv, but if not, set it now
    if [[ -z "$SKY_ORIGINAL_PATH" ]] ; then
        export SKY_ORIGINAL_PATH="$PATH"
    fi

    declare -a linux_paths=()
    declare -a other_paths=()
    for i in "${path[@]}" ; do
        # Note: bash can do this with extglob: [[ "/home/dangl/bin" == @(/home*|/bin) ]] && echo ok || echo fail
        if [[ "$i" == (/bin|/sbin|/usr|/home)* ]] ; then
            linux_paths+=("$i")
        else
            other_paths+=("$i")
        fi
    done

    # Append homebrew to linux_paths now
    # FIXME: Alternative homebrew locations...
    if [[ -d /home/linuxbrew/.linuxbrew/bin ]] ; then
        linux_paths+=("/home/linuxbrew/.linuxbrew/bin" "/home/linuxbrew/.linuxbrew/sbin")
    fi

    # Re-assemble
    path=( "$linux_paths[@]" "$other_paths[@]" )
    unset linux_paths
    unset other_paths
EOF

fi
