#!/bin/bash
# Basic bash script scaffold

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
        log 1 ""
        log 1 "Last command executed:"
        log 1 "    $(printf "%q " "${LAST_COMMAND[@]}")"
        log 1 "Returned exit code ${LAST_COMMAND_EXITCODE}"
    fi
}

################################################################################
# Temp dir handling

# Stores the name of the temporary directory, if it was created
declare -g SCRIPT_TEMP_DIR=''

# Create temporary directory (once) and return its name
# This still works when NO_ACT is set, because the effect is only temporary
require-temp-dir() {
    if [[ -z "$SCRIPT_TEMP_DIR" ]] ; then
        SCRIPT_TEMP_DIR="$(mktemp -d --tmpdir "$THIS_SCRIPT_NAME".XXXXXXXXXX)" \
            || echo "Error: Failed to create temporary directory." 1>&2 \
            || return $?
        # Remove temporary directory when this script finishes
        trap 'remove-temp-dir' EXIT
    fi
}

# Remove temporary directory if it was ever created
remove-temp-dir() {
    if [[ -n "$SCRIPT_TEMP_DIR" ]] ; then
        log 1 "Removing temporary directory: $SCRIPT_TEMP_DIR"
        rm -rf "$SCRIPT_TEMP_DIR" \
            || echo "Error: Failed to remove temporary directory (exitcode $?): $SCRIPT_TEMP_DIR" 1>&2
        SCRIPT_TEMP_DIR=''
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

################################################################################
# Command parts / installation steps

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
        invoke curl -L -o "$windows_destination" "https://github.com/xicesky/dotfiles/raw/main/windows/wsl2-ssh-pageant/wsl2-ssh-pageant.exe" || return 1
        invoke chmod +x "$windows_destination" || return 1
    fi
    # Symlink to linux for ease of use later
    invoke ln -fs "$windows_destination" "$linux_destination" || return 1
    # .zshrc.local will pick it up from here... hopefully.
    # debug using:
    #   ss -a | grep .ssh/agent.sock
}

# During the initial installtion, we don't have bashrc and zshrc to load
# the wsl2-ssh-pageant support - so we use this function will enable this once
init_wsl2-ssh-pageant() {
    # .zshrc.local does this:
    #test -e "${HOME}/bin/my-ssh-pageant.sh" && eval $(${HOME}/bin/my-ssh-pageant.sh)
    # But we don't have "my-ssh-pageant.ssh" either...
    SOCK="$HOME/.ssh/agent.sock"
    WSL2_SSH_PAGEANT_BIN="$HOME/bin/wsl2-ssh-pageant.exe"

    if [[ ! -x "$WSL2_SSH_PAGEANT_BIN" ]] ; then
        echo >&2 "ERROR: $WSL2_SSH_PAGEANT_BIN is not executable."
        return 1
    else
        # FIXME: This also detects the socket on another wsl instance
        if ! ss -a | grep -q "$SOCK"; then
            rm -f "$SOCK"
            ( setsid nohup socat UNIX-LISTEN:"$SOCK,fork" EXEC:"$WSL2_SSH_PAGEANT_BIN" >/dev/null 2>&1 & )
        fi
        export SSH_AUTH_SOCK="$SOCK"
        echo "Please now run the following command:"
        printf 'export SSH_AUTH_SOCK=%q\n' "$SOCK"
    fi
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
    invoke go install mvdan.cc/sh/v3/cmd/shfmt@latest
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

install_homebrew() {
    # Install homebrew
    # if [[ -e /home/linuxbrew ]] ; then
    #     echo "/home/linuxbrew already exists - not installing homebrew"
    #     return 0
    # fi
    if [[ ! -d ~/_dotfiles ]] ; then
        echo "Dotfiles are not in ~/_dotfiles (yet?)" 1>&2
        return 1
    fi
    if [[ ! -f ~/_dotfiles/homebrew/install.sh ]] ; then
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
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    "$HOMEBREW_PREFIX"/bin/brew install gcc
    echo ""
    echo "# Homebrew install done"
}

change_shell() {
    echo ""
    echo "Changing shell to /usr/bin/zsh -- please enter your password:"
    invoke chsh -s /usr/bin/zsh || return 1
}

reboot_message() {
    echo ""
    echo "Done. Now \"reboot\" wsl2 via:"
    echo "    wsl --shutdown"
    echo "    wsl"
}

################################################################################
# Main, argparsing and commands

cmd_init-ssh-pageant() {
    invoke install_prereqs || return 1
    invoke setup_wsl2_dirs || return 1
    invoke setup_wsl2-ssh-pageant || return 1
    invoke init_wsl2-ssh-pageant || return 1
}

cmd_install() {
    invoke install_prereqs || return 1
    invoke setup_wsl2_dirs || return 1
    invoke enable_wsl2_systemd || return 1
    # Don't install by default, we need to deprecate this
    # invoke setup_wsl2-ssh-pageant || return 1
    invoke update_dotfiles || return 1
    install_tools || return 1
    invoke install_homebrew || return 1
    reboot_message # reboot required for systemd
}

cmd_install-tools() {
    install_tools || return 1
    install_homebrew || return 1
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
    echo "    init-ssh-pageant"
    echo "    install-tools"
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
            --help)
                cmd=help
                break
                ;;
            -*)
                { echo "Unknown flag: $arg"; usage; } 1>&2
                return 1
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
