#
# keybinds - Sky's keybinds for Zsh.
#

# Load plugin functions.
# 0=${(%):-%N}
# fpath=(${0:A:h}/functions $fpath)
# autoload -Uz ${0:A:h}/functions/*(.:t)

# Allow mapping Ctrl+S and Ctrl+Q shortcuts
[[ -r ${TTY:-} && -w ${TTY:-} && $+commands[stty] == 1 ]] && stty -ixon <$TTY >$TTY

### From grml: bindkey helpers #########################################################################################

function zrcgotwidget () {
    (( ${+widgets[$1]} ))
}

function zrcbindkey () {
    if (( ARGC )) && zrcgotwidget ${argv[-1]}; then
        bindkey "$@"
    fi
}

function bind2maps () {
    local i sequence widget
    local -a maps

    while [[ "$1" != "--" ]]; do
        maps+=( "$1" )
        shift
    done
    shift

    if [[ "$1" == "-s" ]]; then
        shift
        sequence="$1"
    else
        sequence="${key[$1]}"
    fi
    widget="$2"

    [[ -z "$sequence" ]] && return 1

    for i in "${maps[@]}"; do
        zrcbindkey -M "$i" "$sequence" "$widget"
    done
}

typeset -A key
key=(
    Home     "${terminfo[khome]}"
    End      "${terminfo[kend]}"
    Insert   "${terminfo[kich1]}"
    Delete   "${terminfo[kdch1]}"
    Up       "${terminfo[kcuu1]}"
    Down     "${terminfo[kcud1]}"
    Left     "${terminfo[kcub1]}"
    Right    "${terminfo[kcuf1]}"
    PageUp   "${terminfo[kpp]}"
    PageDown "${terminfo[knp]}"
    BackTab  "${terminfo[kcbt]}"
)

### From grml: keypad support!? ########################################################################################

if (( ${+terminfo[smkx]} )) && (( ${+terminfo[rmkx]} )); then
    function zle-smkx () {
        emulate -L zsh
        printf '%s' ${terminfo[smkx]}
    }
    function zle-rmkx () {
        emulate -L zsh
        printf '%s' ${terminfo[rmkx]}
    }
    function zle-line-init () {
        zle-smkx
    }
    function zle-line-finish () {
        zle-rmkx
    }
    zle -N zle-line-init
    zle -N zle-line-finish
else
    for i in {s,r}mkx; do
        (( ${+terminfo[$i]} )) || grml_missing_features+=($i)
    done
    unset i
fi

### From grml: power completion ########################################################################################

# power completion / abbreviation expansion / buffer expansion
# see http://zshwiki.org/home/examples/zleiab for details
# less risky than the global aliases but powerful as well
# just type the abbreviation key and afterwards 'ctrl-x .' to expand it
declare -A abk
setopt extendedglob
setopt interactivecomments
abk=(
    '...'  '../..'
    '....' '../../..'
    'BG'   '& exit'
    'C'    '| wc -l'
    'G'    '|& grep '${grep_options:+"${grep_options[*]}"}
    'H'    '| head'
    'Hl'   ' --help |& less -r'    #d (Display help in pager)
    'L'    '| less'
    'LL'   '|& less -r'
    'M'    '| most'
    'N'    '&>/dev/null'           #d (No Output)
    'R'    '| tr A-z N-za-m'       #d (ROT13)
    'SL'   '| sort | less'
    'S'    '| sort -u'
    'T'    '| tail'
    'V'    '|& vim -'
#A# end
    'co'   './configure && make && sudo make install'
)

function zleiab () {
    emulate -L zsh
    setopt extendedglob
    local MATCH

    LBUFFER=${LBUFFER%%(#m)[.\-+:|_a-zA-Z0-9]#}
    LBUFFER+=${abk[$MATCH]:-$MATCH}
}

zle -N zleiab

function help-show-abk () {
    zle -M "$(print "Available abbreviations for expansion:"; print -a -C 2 ${(kv)abk})"
}

zle -N help-show-abk

# press "ctrl-x d" to insert the actual date in the form yyyy-mm-dd
function insert-datestamp () { LBUFFER+=${(%):-'%D{%Y-%m-%d}'}; }
zle -N insert-datestamp

#zrcautoload insert-unicode-char &&
zle -N insert-unicode-char

### My personal preferences ############################################################################################

#k# Perform abbreviation expansion
bind2maps emacs viins       -- -s '^x.' zleiab
#k# Display list of abbreviations that would expand
bind2maps emacs viins       -- -s '^xb' help-show-abk
#k# mkdir -p <dir> from string under cursor or marked area
#bind2maps emacs viins       -- -s '^xM' inplaceMkDirs
#k# display help for keybindings and ZLE
# bind2maps emacs viins       -- -s '^xz' help-zle

#k# search history backward for entry beginning with typed text
bind2maps emacs viins       -- -s '^xp' history-beginning-search-backward-end
#k# search history forward for entry beginning with typed text
bind2maps emacs viins       -- -s '^xP' history-beginning-search-forward-end
#k# search history backward for entry beginning with typed text
bind2maps emacs viins       -- PageUp history-beginning-search-backward-end
#k# search history forward for entry beginning with typed text
bind2maps emacs viins       -- PageDown history-beginning-search-forward-end

#k# Insert a timestamp on the command line (yyyy-mm-dd)
bind2maps emacs viins       -- -s '^xd' insert-datestamp

# insert unicode character
# usage example: 'ctrl-x i' 00A7 'ctrl-x i' will give you an §
# See for example http://unicode.org/charts/ for unicode characters code
#k# Insert Unicode character
bind2maps emacs viins       -- -s '^xi' insert-unicode-char

function print_key() {
    stty  raw min 1 time 20 -echo
    dd count=1 2> /dev/null | xxd
    stty sane
    echo
}

# Tell Zephyr this plugin is loaded.
zstyle ":zephyr:plugin:keybinds" loaded 'yes'
