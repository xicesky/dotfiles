#!/bin/bash

# Load iterm2 shell integration if available
if [[ -e "${HOME}/.iterm2_shell_integration.zsh" ]] ; then
    # shellcheck disable=SC2016
    echo 'source "${HOME}/.iterm2_shell_integration.zsh"'
fi
