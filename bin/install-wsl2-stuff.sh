#!/bin/bash
# Basic bash script scaffold

# Verbosity level, 0 is quiet, 1 is normal, 2 prints commands
VERBOSITY="${VERBOSITY:-1}"

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
        log 1 ""
        log 1 "Last command executed:"
        log 1 "    $(printf "%q " "${LAST_COMMAND[@]}")"
        log 1 "Returned exit code ${LAST_COMMAND_EXITCODE}"
    fi
}

# Stores the name of the temporary directory, if it was created
declare -g SCRIPT_TEMP_DIR=''

# Create temporary directory (once) and return its name
# This still works when NO_ACT is set, because the effect is only temporary
require-temp-dir() {
    if [[ -z "$SCRIPT_TEMP_DIR" ]] ; then
        SCRIPT_TEMP_DIR="$(mktemp -d --tmpdir "$THIS_SCRIPT_NAME".XXXXXXXXXX)" \
            || error 1 "Failed to create temporary directory." \
            || return $?
        # Remove temporary directory when this script finishes
        trap 'remove-temp-dir' EXIT
    fi
}

# Remove temporary directory if it was ever created
remove-temp-dir() {
    if [[ -n "$SCRIPT_TEMP_DIR" ]] ; then
        log 1 "Removing temporary directory: $SCRIPT_TEMP_DIR"
        # We can't use "error" here because this function is called from trap
        rm -rf "$SCRIPT_TEMP_DIR" \
            || echo "Error: Failed to remove temporary directory (exitcode $?): $SCRIPT_TEMP_DIR" 1>&2
        SCRIPT_TEMP_DIR=''
    fi
}

install_prereqs() {
    invoke sudo apt-get update || return 1
    invoke sudo apt-get dist-upgrade || return 1
    invoke sudo apt-get install -y git etckeeper python3-pip wslu socat iproute2 || return 1
}

setup_wsl2_dirs() {
    invoke mkdir -p ~/bin || return 1
    WIN_HOME="$(wslpath -a "$(wslvar USERPROFILE)")"
    [[ -d "$WIN_HOME" ]] || return 1
    invoke ln -fs "$WIN_HOME" ~/win-home || return 1
    invoke ln -fs win-home/.m2 ~/.m2 || return 1
    invoke ln -fs win-home/.npmrc ~/.npmrc || return 1
}

setup_wsl2-ssh-pageant() {
    # FIXME: https://polansky.co/blog/a-better-windows-wsl-openssh-experience/
    # Make pageant available via
    # https://github.com/BlackReloaded/wsl2-ssh-pageant
    windows_destination="$WIN_HOME/bin/wsl2-ssh-pageant.exe"
    linux_destination="$HOME/bin/wsl2-ssh-pageant.exe"

    if [[ ! -f "$windows_destination" ]] ; then
        invoke curl -L -o "$windows_destination" "https://github.com/xicesky/dotfiles/raw/main/windows/wsl2-ssh-pageant/wsl2-ssh-pageant.exe"
        invoke chmod +x "$windows_destination"
    fi
    # Symlink to linux for ease of use later
    invoke ln -fs "$windows_destination" "$linux_destination"
    # .zshrc.local will pick it up from here... hopefully.
    # debug using:
    #   ss -a | grep .ssh/agent.sock
}

install_tools() {
    invoke sudo apt-get install -y \
        pigz gzrt gzip bzip2 lzma p7zip-full p7zip-rar \
        bc pv netcat-openbsd curl wget nmap ncftp \
        zsh vim mc sudo \
        dnsutils tcpdump \
        apt-transport-https aptitude asciidoctor ruby-rouge \
        ca-certificates jq shellcheck xmlstarlet golang \
        || return 1

    # TODO: Packages requiring apt sources
    # helm terraform

    # Install via go
    invoke go install github.com/mikefarah/yq/v4@latest
}

enable_wsl2_systemd() {
    # Enable systemd
    {
        echo "[boot]"
        echo "systemd=true"
    } | sudo sh -c 'cat >/etc/wsl.conf'
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

cmd_install-ssh-pageant() {
    invoke install_prereqs || return 1
    invoke setup_wsl2_dirs || return 1
    invoke setup_wsl2-ssh-pageant || return 1
}

cmd_install() {
    invoke install_prereqs || return 1
    invoke setup_wsl2_dirs || return 1
    # Don't install by default, we need to deprecate this
    # invoke setup_wsl2-ssh-pageant || return 1
    invoke update_dotfiles || return 1
    invoke chsh -s /usr/bin/zsh || return 1

    echo "Done. Now \"reboot\" wsl2 via:"
    echo "    wsl --shutdown"
    echo "    wsl"
}

cmd_help() {
    usage
}

usage() {
    echo "Usage: $0 [flags...] <command...>"
    echo "Flags:"
    echo "    -v    Increase verbosity level"
    echo "    -q    Decrease verbosity level"
    echo ""
    echo "Available commands:"
    echo "    install"
    echo "    install-ssh-pageant"
    echo "    help"
    echo ""
}

main() {
    declare -a args=()
    declare -i argno=0
    declare cmd="install"
    declare cmderr=0
    while [[ $# -gt 0 ]] ; do
        arg="$1"; shift
        case "$arg" in
            -v) (( VERBOSITY++ )) ;;
            -q) (( VERBOSITY-- )) ;;
            -*)
                { echo "Unknown flag: $arg"; usage; } 1>&2
                ;;
            *)
                (( argno++ ))
                if [[ "$argno" -eq 1 ]] ; then
                    cmd="$arg"
                else
                    args=( "$args" "$arg" )
                fi
                ;;
        esac
    done
    if [[ -z "$cmd" ]] ; then
        usage
    elif [[ $(type -t "cmd_$cmd") == function ]] ; then
        "cmd_$cmd" "$args"
        cmderr="$?"
        if [[ "$cmderr" -ne 0 ]] ; then
            echo ""
            report_command_failure
            echo ""
        fi
        return "$cmderr"
    else
        { echo "Unknown command: $cmd"; usage; } 1>&2
        return 1
    fi
}

main "$@"
