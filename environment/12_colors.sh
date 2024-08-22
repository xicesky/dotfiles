#!/bin/bash

if !which tput >/dev/null 2>&1 ; then
    function tput() {
        return 0
    }
else
    tput_executable="$(which tput)"
    function tput() {
        "$tput_executable" "$@"
    }
fi

found=false
for dircolors_cmd in dircolors gdircolors; do
    if which "$dircolors_cmd" >/dev/null 2>&1 ; then
        found=true
        dircolors_executable="$(which "$dircolors_cmd")"
        function dircolors() {
            "$dircolors_executable" "$@"
        }
    fi
done
if ! $found ; then
    function dircolors() {
        return 0
    }
fi

function colormap() {
    for y in {0..31}; do
        for x in {0..7}; do
            (( i=y*8+x ))
            [[ $x -gt 0 ]] && echo -n "    "
            printf "$(tput setab 15 setaf $i)☐$(tput setab 0 setaf $i)☐ tput setaf %-3d" "$i"
        done
        echo "$(tput sgr0)"
    done
    echo ""
    for y in {0..31}; do
        for x in {0..7}; do
            (( i=y*8+x ))
            [[ $x -gt 0 ]] && echo -n "    "
            printf "$(tput setab $i setaf 0)☐$(tput setab $i setaf 7)☐ tput setaf %-3d" "$i"
        done
        echo "$(tput sgr0)"
    done
    echo "$(tput sgr0)"
}

declare -f colormap

# Colorize man pages.
echo "if [[ \"\$TERM\" != 'dumb' ]] ; then"

if [[ "$SHELL_TYPE" = "zsh" ]] ; then
    cat <<'EOF'
# Built-in zsh colors.
autoload -Uz colors && colors

# Colorize man pages.
export LESS_TERMCAP_md=$fg_bold[blue]   # start bold
export LESS_TERMCAP_mb=$fg_bold[blue]   # start blink
export LESS_TERMCAP_so=$'\e[00;47;30m'  # start standout: white bg, black fg
export LESS_TERMCAP_us=$'\e[04;35m'     # start underline: underline magenta
export LESS_TERMCAP_se=$reset_color     # end standout
export LESS_TERMCAP_ue=$reset_color     # end underline
export LESS_TERMCAP_me=$reset_color     # end bold/blink
EOF

else
    # bash: use tput

    cat <<'EOF'
# Colorize man pages.
export reset_color="$(tput sgr0)"
export LESS_TERMCAP_md="$(tput bold setaf 12)"  # start bold
export LESS_TERMCAP_mb="$(tput bold setaf 12)"  # start blink
export LESS_TERMCAP_so=$'\e[00;47;30m'  # start standout: white bg, black fg
export LESS_TERMCAP_us=$'\e[04;35m'     # start underline: underline magenta
export LESS_TERMCAP_se=$reset_color     # end standout
export LESS_TERMCAP_ue=$reset_color     # end underline
export LESS_TERMCAP_me=$reset_color     # end bold/blink
EOF

fi

if [[ -n "$SKY_DOTFILES" ]] ; then
    cat <<'EOF'
# Set LS_COLORS using (g)dircolors if found.
if [[ -z "$LS_COLORS" && -n "$SKY_DOTFILES" ]]; then
EOF
    dircolors -b "$SKY_DOTFILES/colors/.dircolors"
    echo "fi"
fi

# FIXME: BSD systems
# # For BSD systems, set LSCOLORS
# export CLICOLOR=${CLICOLOR:-1}
# export LSCOLORS="${LSCOLORS:-exfxcxdxbxGxDxabagacad}"

# Aliases
cat <<'EOF'
alias grep="grep --color=auto"
alias ls="ls --color=auto"
alias diff="diff --color"
EOF

echo "fi"
