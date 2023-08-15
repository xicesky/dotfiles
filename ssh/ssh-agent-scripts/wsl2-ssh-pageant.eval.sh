#!/bin/bash

# Forwards ssh-agent to pagent running on windows.
# Source: https://github.com/BlackReloaded/wsl2-ssh-pageant
# Installation see setup_wsl2-ssh-pageant function in install-wsl2-stuff.sh

# Kinda deprecated - use openssh's ssh-agent on win instead!
# See wsl2-ssh-agent-relay.sh

SOCK="$HOME/.ssh/agent.sock"
WSL2_SSH_PAGEANT_BIN="$HOME/bin/wsl2-ssh-pageant.exe"

if [[ ! -x "$WSL2_SSH_PAGEANT_BIN" ]] ; then
    echo >&2 "WARNING: $WSL2_SSH_PAGEANT_BIN is not executable."
else 
    if ! ss -a | grep -q "$SOCK"; then
        rm -f "$SOCK"
        ( setsid nohup socat UNIX-LISTEN:"$SOCK,fork" EXEC:"$WSL2_SSH_PAGEANT_BIN" >/dev/null 2>&1 & )
    fi

    printf 'export SSH_AUTH_SOCK=%q\n' "$SOCK"
fi
