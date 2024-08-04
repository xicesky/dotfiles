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
# Command parts / installation steps

install_packages() {
    invoke sudo apt-get install vim htop iotop iptraf-ng p7zip-full mc curl wget \
	nmap pigz gzrt gzip bzip2 hwinfo ltrace strace lzma \
	ncftp netcat-openbsd p7zip-rar pv \
	bc zsh dnsutils git gnupg2 \
    ca-certificates jq shellcheck xmlstarlet golang \
    aptitude asciidoctor ruby-rouge \
    || return 1

    # Graphical tools
    invoke sudo apt-get install \
    xmonad xmobar trayer xsel rxvt-unicode suckless-tools gmrun \
    libghc-xmonad-contrib-dev gnome-core ttf-bitstream-vera \
    || return 1
}

install_fonts() {
    if [[ -n "$XDG_DATA_HOME" ]] ; then
        fontdir="$XDG_DATA_HOME/fonts"
    else
        fontdir="$HOME/.local/share/fonts"
    fi
    invoke mkdir -p "$fontdir" || return 1
    invoke cp ~/_dotfiles/fonts/source-code-pro/OTF/*.otf "$fontdir/"
    invoke cp ~/_dotfiles/fonts/source-code-pro/TTF/*.ttf "$fontdir/"
    invoke cp ~/_dotfiles/fonts/nerd-fonts/Meslo/*.ttf "$fontdir/"
    invoke cp ~/_dotfiles/fonts/nerd-fonts/SourceCodePro/*.ttf "$fontdir/"
}

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
    if [[ -f ~/.bashrc ]] ; then
        { 
            echo "Warning: ~/.bashrc already exists, not linking"
            echo "Remove it and rerun this installer it to get the actual bash configuration"
        } 1>&2
    fi
    if [[ -f ~/.bash_logout ]] ; then
        { 
            echo "Warning: ~/.bash_logout already exists, not linking"
            echo "Remove it and rerun this installer it to get the actual bash configuration"
        } 1>&2
    fi
    lins "_dotfiles"/{vim/.vim,vim/.vimrc,git/.gitconfig,tmux/.tmux.conf,zsh/.zshenv,bash/.bashrc,bash/.bash_logout} ~ || return 1
    
    mkdir -p ~/.config/zsh || return 1
    mapfile -d $'\0' SOURCES < <( ( cd ~ && find _dotfiles/zsh/zdotdir -mindepth 1 -maxdepth 1 -printf "../../%p\0") )
    if [[ "${#SOURCES[@]}" -lt 1 ]] ; then
        echo "Failed to find any sources in _dotfiles/zsh/zdotdir" 1>&2
        return 1
    fi
    invoke lins "${SOURCES[@]}" ~/.config/zsh || return 1

    mkdir -p ~/.config/bash || return 1
    mapfile -d $'\0' SOURCES < <( ( cd ~ && find _dotfiles/bash/bash_dotdir -mindepth 1 -maxdepth 1 -printf "../../%p\0") )
    if [[ "${#SOURCES[@]}" -lt 1 ]] ; then
        echo "Failed to find any sources in _dotfiles/bash/bash_dotdir" 1>&2
        return 1
    fi
    invoke lins "${SOURCES[@]}" ~/.config/bash || return 1
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
    invoke setup_dirs || return 1
    invoke update_dotfiles || return 1
    install_dotfiles || return 1
    # Homebrew currently doesn't work because of missing permissions
    #invoke install_homebrew || return 1
    change_shell || return 1
}

cmd_install-fonts() {
    invoke install_fonts || return 1
}

cmd_temp() {
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
