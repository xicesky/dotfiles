#!/bin/bash

# Uses wsl-ssh-agent-relay.sh from https://github.com/rupor-github/wsl-ssh-agent/blob/master/docs/wsl-ssh-agent-relay
# to forward to the native ssh-agent on windows

# * Set up ssh-agent on windows first:
#       https://learn.microsoft.com/de-de/windows-server/administration/openssh/openssh_keymanagement
# * Dotfiles NEED TO BE IN ~/_dotfiles (for now)
# * Install npiperelay:  https://github.com/jstarks/npiperelay
#    * Via choco: choco install -y npiperelay
#    * Or via go: go get -u github.com/jstarks/npiperelay
# * Install socat
#    * Via apt: sudo apt-get install socat
# * Symlink this script to ~/bin/my-ssh-agent.eval.sh
#     ( cd ~/bin && ln -s ~/_dotfiles/ssh/ssh-agent-scripts/wsl2-ssh-agent-relay.eval.sh my-ssh-agent.eval.sh )
# You can check open sockets via ss:
#   ss -nxap
# Cool comic infos here <3 https://en.rattibha.com/thread/1446683409644851201

DOTFILES_DIR=~/_dotfiles
#NPIPERELAY_BIN=$(which npiperelay.exe)
# FIXME: This is a hack, search the windows path instead
#   or just provide the exe in dotfiles
NPIPERELAY_BIN=/mnt/c/ProgramData/chocolatey/lib/npiperelay/tools/npiperelay.exe
SOCK="$HOME/.ssh/wsl-ssh-agent.sock"

activate-ssh-agent() {
    # ${HOME}/.local/bin/wsl-ssh-agent-relay start
    [[ -d "$DOTFILES_DIR" ]] || {
        echo "ERROR: Could not find dotfiles in $DOTFILES_DIR" 1>&2
        return 1
    }
    [[ -x "$DOTFILES_DIR/ssh/ssh-agent-scripts/wsl-ssh-agent-relay.sh" ]] || {
        echo "ERROR: Could not find wsl-ssh-agent-relay.sh in $DOTFILES_DIR" 1>&2
        return 1
    }
    # Override environment variables in wsl-ssh-agent-relay.sh
    export RELAY_BIN="$NPIPERELAY_BIN"
    export PIDFILE="${HOME}/.ssh/wsl-ssh-agent-relay.pid"
    export WSL_AGENT_SSH_SOCK="$SOCK"

    "$DOTFILES_DIR/ssh/ssh-agent-scripts/wsl-ssh-agent-relay.sh" start || return 1
    printf 'export SSH_AUTH_SOCK=%q\n' "$SOCK"
}

activate-ssh-agent
