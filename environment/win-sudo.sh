#!/bin/bash

# Load win-sudo (MSYS)

# Win-Sudo fail: doesn't work with zsh
#test -f "${HOME}/bin/win-sudo/s/path.sh" && source "${HOME}/bin/win-sudo/s/path.sh"

if [[ -d "${HOME}/bin/win-sudo/s" ]] ; then
    append_to_path "${HOME}/bin/win-sudo/s"
fi
