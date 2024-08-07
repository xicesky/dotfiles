#!/bin/bash
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
# Configuration

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/_dotfiles}"
# Everything else is configured via _dotfiles/installer/install.sh

configuration_load() {
    if [[ -x "$DOTFILES_DIR/installer/install.sh" ]] ; then
        eval "$("$DOTFILES_DIR/installer/install.sh" -q info)"
    else
        log 0 "Dotfiles main installer $DOTFILES_DIR/installer/install.sh not found or not executable"
        return 1
    fi
}

################################################################################
# Command parts / installation steps

install_packages() {
    invoke sudo apt-get install -y \
        vim p7zip-full p7zip-rar lzma pigz gzrt gzip bzip2 \
        mc curl wget nmap hwinfo ltrace strace htop iotop iptraf-ng tcpdump \
        ncftp netcat-openbsd pv dos2unix \
        bc zsh dnsutils git gnupg2 \
        ca-certificates jq shellcheck xmlstarlet golang \
        aptitude asciidoctor ruby-rouge postgresql-client \
        || return 1
    
    # Desktop
    invoke sudo apt-get install -y \
        xmonad xmobar trayer xsel rxvt-unicode suckless-tools gmrun \
        libghc-xmonad-contrib-dev gnome-core \
        || return 1

    # Graphical tools
    invoke sudo apt-get install -y \
        ttf-bitstream-vera remmina remmina-plugin-spice \
        || return 1
}

install_homebrew() {
    # Install homebrew
    if [[ -e /home/linuxbrew ]] ; then
        echo "/home/linuxbrew already exists - not installing homebrew"
        return 0
    fi
    if [[ ! -d ~/_dotfiles ]] ; then
        echo "Dotfiles are not in ~/_dotfiles (yet?)" 1>&2
        return 1
    fi
    if [[ ! -f ~/_dotfiles/homebrew/install.sh ]] ; then
        #shellcheck disable=SC2088
        echo "~/_dotfiles/homebrew/install.sh is missing" 1>&2
        return 1
    fi

    echo "################################################################################"
    echo "# Starting homebrew install"
    echo ""
    /bin/bash ~/_dotfiles/homebrew/install.sh || return 1
    if [[ ! -x /home/linuxbrew/.linuxbrew/bin/brew ]] ; then
        echo "Homebrew did not install /home/linuxbrew/.linuxbrew/bin/brew ???" 1>&2
        return 1
    fi
    echo "# Homebrew install done"
}

change_shell() {
    # chsh currently doesn't work, because my user is not in /etc/passwd
    #invoke chsh -s /usr/bin/zsh || return 1
    true
}

################################################################################
# Main, argparsing and commands

cmd_install() {
    invoke install_packages || return 1
    configuration_load || return 1
    invoke "$DOTFILES_DIR/installer/install.sh" install
    # Homebrew currently doesn't work because of missing permissions
    #invoke install_homebrew || return 1
    change_shell || return 1
}

cmd_install-fonts() {
    configuration_load || return 1
    invoke "$DOTFILES_DIR/installer/install.sh" install-fonts || return 1
}

cmd_temp() {
    configuration_load || return 1
    invoke install_packages || return 1
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
