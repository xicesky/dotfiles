
# Stuff from grml zsh not yet covered
if false ; then

    # Load a few modules
    is4 && \
    for mod in parameter complist deltochar mathfunc ; do
        zmodload -i zsh/${mod} 2>/dev/null
        grml_status_feature mod:$mod $?
    done && builtin unset -v mod

    # autoload zsh modules when they are referenced
    if is4 ; then
        zmodload -a  zsh/stat    zstat
        zmodload -a  zsh/zpty    zpty
        zmodload -ap zsh/mapfile mapfile
    fi

    ## correction
    # some people don't like the automatic correction - so run 'NOCOR=1 zsh' to deactivate it
    if [[ "$NOCOR" -gt 0 ]] ; then
        zstyle ':completion:*' completer _oldlist _expand _force_rehash _complete _files _ignored
        setopt nocorrect
    else
        # try to be smart about when to use what completer...
        setopt correct
        zstyle -e ':completion:*' completer '
            if [[ $_last_try != "$HISTNO$BUFFER$CURSOR" ]] ; then
                _last_try="$HISTNO$BUFFER$CURSOR"
                reply=(_complete _match _ignored _prefix _files)
            else
                if [[ $words[1] == (rm|mv) ]] ; then
                    reply=(_complete _files)
                else
                    reply=(_oldlist _expand _force_rehash _complete _ignored _correct _approximate _files)
                fi
            fi'
    fi

    # power completion / abbreviation expansion / buffer expansion
    # see http://zshwiki.org/home/examples/zleiab for details
    # less risky than the global aliases but powerful as well
    # just type the abbreviation key and afterwards 'ctrl-x .' to expand it
    declare -A abk
    setopt extendedglob
    setopt interactivecomments
    abk=(
    #   key   # value                  (#d additional doc string)
    #A# start
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

    # press esc-m for inserting last typed word again (thanks to caphuso!)
    function insert-last-typed-word () { zle insert-last-word -- 0 -1 };
    zle -N insert-last-typed-word;


    # ??????????????

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

    # ??? May be useful?

    # chpwd_profiles(): Directory Profiles, Quickstart:
    #
    # In .zshrc.local:
    #
    #   zstyle ':chpwd:profiles:/usr/src/grml(|/|/*)'   profile grml
    #   zstyle ':chpwd:profiles:/usr/src/debian(|/|/*)' profile debian
    #   chpwd_profiles
    #
    # For details see the `grmlzshrc.5' manual page.


    # Prompt setup for grml:

    # set colors for use in prompts (modern zshs allow for the use of %F{red}foo%f
    # in prompts to get a red "foo" embedded, but it's good to keep these for
    # backwards compatibility).
    if is437; then
        BLUE="%F{blue}"
        RED="%F{red}"
        GREEN="%F{green}"
        CYAN="%F{cyan}"
        MAGENTA="%F{magenta}"
        YELLOW="%F{yellow}"
        WHITE="%F{white}"
        NO_COLOR="%f"
    elif zrcautoload colors && colors 2>/dev/null ; then
        BLUE="%{${fg[blue]}%}"
        RED="%{${fg_bold[red]}%}"
        GREEN="%{${fg[green]}%}"
        CYAN="%{${fg[cyan]}%}"
        MAGENTA="%{${fg[magenta]}%}"
        YELLOW="%{${fg[yellow]}%}"
        WHITE="%{${fg[white]}%}"
        NO_COLOR="%{${reset_color}%}"
    else
        BLUE=$'%{\e[1;34m%}'
        RED=$'%{\e[1;31m%}'
        GREEN=$'%{\e[1;32m%}'
        CYAN=$'%{\e[1;36m%}'
        WHITE=$'%{\e[1;37m%}'
        MAGENTA=$'%{\e[1;35m%}'
        YELLOW=$'%{\e[1;33m%}'
        NO_COLOR=$'%{\e[0m%}'
    fi

    # First, the easy ones: PS2..4:

    # secondary prompt, printed when the shell needs more information to complete a
    # command.
    PS2='\`%_> '
    # selection prompt used within a select loop.
    PS3='?# '
    # the execution trace prompt (setopt xtrace). default: '+%N:%i>'
    PS4='+%N:%i:%_> '

    # TODO grml line 1971
    # gather version control information for inclusion in a prompt

    # 'hash' some often used directories
    #d# start
    hash -d deb=/var/cache/apt/archives
    hash -d doc=/usr/share/doc
    hash -d linux=/lib/modules/$(command uname -r)/build/
    hash -d log=/var/log
    hash -d slog=/var/log/syslog
    hash -d src=/usr/src
    hash -d www=/var/www
    #d# end

    # do we have GNU ls with color-support?
    if [[ "$TERM" != dumb ]]; then
        #a1# List files with colors (\kbd{ls \ldots})
        alias ls="command ls ${ls_options:+${ls_options[*]}}"
        #a1# List all files, with colors (\kbd{ls -la \ldots})
        alias la="command ls -la ${ls_options:+${ls_options[*]}}"
        #a1# List files with long colored list, without dotfiles (\kbd{ls -l \ldots})
        alias ll="command ls -l ${ls_options:+${ls_options[*]}}"
        #a1# List files with long colored list, human readable sizes (\kbd{ls -hAl \ldots})
        alias lh="command ls -hAl ${ls_options:+${ls_options[*]}}"
        #a1# List files with long colored list, append qualifier to filenames (\kbd{ls -l \ldots})\\&\quad(\kbd{/} for directories, \kbd{@} for symlinks ...)
        alias l="command ls -l ${ls_options:+${ls_options[*]}}"
    else
        alias la='command ls -la'
        alias ll='command ls -l'
        alias lh='command ls -hAl'
        alias l='command ls -l'
    fi

    # TODO: more color command aliases in grml config ...

    alias ...='cd ../../'

    #f1# Reload an autoloadable function
    function freload () { while (( $# )); do; unfunction $1; autoload -U $1; shift; done }
    compdef _functions freload

    # a wrapper for vim, that deals with title setting
    #   VIM_OPTIONS
    #       set this array to a set of options to vim you always want
    #       to have set when calling vim (in .zshrc.local), like:
    #           VIM_OPTIONS=( -p )
    #       This will cause vim to send every file given on the
    #       commandline to be send to it's own tab (needs vim7).
    if check_com vim; then
        function vim () {
            VIM_PLEASE_SET_TITLE='yes' command vim ${VIM_OPTIONS} "$@"
        }
    fi

    # load the lookup subsystem if it's available on the system
    zrcautoload lookupinit && lookupinit

    #f5# Create Directory and \kbd{cd} to it
    function mkcd () {
        if (( ARGC != 1 )); then
            printf 'usage: mkcd <new-directory>\n'
            return 1;
        fi
        if [[ ! -d "$1" ]]; then
            command mkdir -p "$1"
        else
            printf '`%s'\'' already exists: cd-ing.\n' "$1"
        fi
        builtin cd "$1"
    }

fi
