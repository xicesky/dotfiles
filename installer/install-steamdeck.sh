#!/bin/sh
# FIXME: Share functions with other installers (install-wsl2-stuff.sh)

################################################################################
# Verbosity, command logging

# Verbosity level, 0 is quiet, 1 is normal, 2 prints commands
VERBOSITY="${VERBOSITY:-2}"

# Don't act, just check (and print commands)
NO_ACT="${NO_ACT:-false}"

# Display a message if verbosity level allows
log() {
    declare prefix="$DEFAULT_LOG_PREFIX"
    [[ "$1" = "-p" ]] && { shift; prefix="$1"; shift; }
    declare level="$1"; shift
    if [[ "$VERBOSITY" -ge "$level" ]] ; then
        echo "$prefix$*" 1>&2
    fi
}

# Same but use printf
logf() {
    declare level="$1"; shift
    # Passing a formatting string is exactly what we intend here
    # shellcheck disable=SC2059
    log "$level" "$(printf "$@")"
}

# Stores the last command executed by invoke()
declare -a LAST_COMMAND
LAST_COMMAND=()

# ... and it's exit code
declare -g LAST_COMMAND_EXITCODE
LAST_COMMAND_EXITCODE=0

# Log and invoke a command or skip it if NO_ACT is set
# This actually works only for simple commands, you can't use it to:
#   - Invoke commands that use pipes or redirections
#   - Invoke compound commands (expressions)
#   - Set variables
invoke() {
    declare redir=""
    while [[ $# -gt 0 ]] ; do
        case "$1" in
            "-o")   shift; redir="$1"; shift ;;
            -*)     echo "invoke: Unknown flag: $arg" 1>&2; return 1 ;;
            *)      break ;;
        esac
    done
    LAST_COMMAND=("$@")
    log -p "" 2 "$(printf "%q " "$@")"
    if ! "$NO_ACT" ; then
        LAST_COMMAND_EXITCODE=0
        if [[ -z "$redir" ]] ; then "$@"; else "$@" >"$redir"; fi
        LAST_COMMAND_EXITCODE="$?"
        return $LAST_COMMAND_EXITCODE
    fi
}

# Report the last command, if it failed
report_command_failure() {
    if [[ "$LAST_COMMAND_EXITCODE" -ne 0 ]] ; then
        log 1 "Last command executed:"
        log 1 "    $(printf "%q " "${LAST_COMMAND[@]}")"
        log 1 "Returned exit code ${LAST_COMMAND_EXITCODE}"
    fi
}

################################################################################
# Utilities

# Search for the given executable in PATH
# avoids a dependency on the `which` command
which() {
    # Alias to Bash built-in command `type -P`
    type -P "$@"
}

# Put (multiple) relative symlink(s) in a target directory
# Skips without error if file exists
# Sources are relative to the target directory, not the current directory!
lins() {
    declare -a sources=()
    while [[ $# -gt 1 ]] ; do
        sources+=( "$1" ); shift
    done
    declare target="$1"; shift
    if [[ ! -d "$target" ]] ; then
        echo "Error: Target must be a directory, but is: $target" 1>&2
        return 1
    fi
    declare i
    declare bn
    for i in "${sources[@]}" ; do
        bn="$(basename "$i")"
        # FIXME: Check that source exists
        if [[ -e "$target/$bn" ]] ; then
            echo "$target/$bn already exists." 1>&2
            continue
        fi
        invoke ln -s "$i" "$target/$bn" || return 1
    done
}

################################################################################
# Command parts / installation steps

setup_dirs() {
    invoke mkdir -p ~/bin || return 1
}

update_dotfiles() {
    # Check if agent is up at all
    if [[ "$(ssh-add -l 2>/dev/null | wc -l)" -eq 0 ]] ; then
        echo "No keys found in ssh-agent. Check via: ssh-add -l" 1>&2
        return 1
    fi

    # Klöne tze repositorie
    if [[ ! -d ~/_dotfiles ]] ; then
        invoke git clone --recurse-submodules "git@github.com:xicesky/dotfiles.git" ~/_dotfiles || return 1
    else
        ( cd ~/_dotfiles && invoke git pull; ) || return 1
    fi
}

install_dotfiles() {
    # Binaries first
    for i in \
        datetag ff git-multi-st git-showtool kube-helper.sh list-git-repos \
        open query-xml ry where-is-java winmerge \
        ; do
        lins "../_dotfiles/bin/$i" ~/bin || return 1
    done
    # FIXME?
    # if [[ ! -e "bin/my-ssh-agent.eval.sh" ]] ; then
    #     invoke ln -s ../_dotfiles/ssh/ssh-agent-scripts/wsl2-ssh-agent-relay.eval.sh bin/my-ssh-agent.eval.sh || return 1
    # fi
    lins "_dotfiles"/{vim/.vim,vim/.vimrc,git/.gitconfig,tmux/.tmux.conf,zsh/.zshenv} ~ || return 1
    mkdir -p ~/.config/zsh
    mapfile -d $'\0' SOURCES < <(find _dotfiles/zsh/zdotdir -mindepth 1 -maxdepth 1 -printf "../../%p\0")
    lins "${SOURCES[@]}" ~/.config/zsh || return 1
}

change_shell() {
    echo "" >&2
    echo "WARNING: Changing shell on steam deck will break the steam gaming mode somehow." >&2
    echo "         Not changing shell for now." >&2
    #invoke chsh -s /usr/bin/zsh || return 1
}

################################################################################
# Main, argparsing and commands

cmd_install() {
    invoke setup_dirs || return 1
    invoke update_dotfiles || return 1
    install_dotfiles || return 1
    # TODO: Homebrew
    # invoke install_homebrew || return 1
    change_shell || return 1
}

cmd_help() {
    usage
}

usage() {
    echo "Usage: $0 [global flags...] <command...>"
    echo "Global flags:"
    echo "    -v    Increase verbosity level"
    echo "    -q    Decrease verbosity level"
    echo "    --help  Show usage and exit"
    echo ""
    echo "Available commands:"
    echo "    install"
    echo "    help    Show usage and exit"
    echo ""
}

main() {
    declare cmd=""
    declare cmderr=0
    while [[ $# -gt 0 ]] ; do
        arg="$1"; shift
        case "$arg" in
            -v) (( VERBOSITY++ )) ;;
            -q) (( VERBOSITY-- )) ;;
            --help)
                cmd=help
                break
                ;;
            -*)
                { echo "Unknown flag: $arg"; usage; } 1>&2
                return 1
                ;;
            *)
                    cmd="$arg"
                break
                ;;
        esac
    done
    if [[ -z "$cmd" ]] ; then
        usage
    elif [[ $(type -t "cmd_$cmd") == function ]] ; then
        "cmd_$cmd" "$@"
        cmderr="$?"
        if [[ "$cmderr" -ne 0 && "$LAST_COMMAND_EXITCODE" -ne 0 ]] ; then
            report_command_failure 1>&2
            echo "" 1>&2
        fi
        return "$cmderr"
    else
        { echo "Unknown command: $cmd"; usage; } 1>&2
        return 1
    fi
}

main "$@"
