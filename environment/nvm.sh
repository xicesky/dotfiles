#!/bin/bash

# Load nvm (Node Version Manager): https://github.com/nvm-sh/nvm
if [[ -d "$HOME/.nvm" ]] ; then
    NVM_DIR="$HOME/.nvm"
    # shellcheck disable=SC2016
    echo 'export NVM_DIR="$HOME/.nvm"'
    if [ -s "$NVM_DIR/nvm.sh" ] ; then
        # shellcheck disable=SC2016
        echo 'source "$NVM_DIR/nvm.sh"  # This loads nvm'
    elif [ -s "/home/linuxbrew/.linuxbrew/opt/nvm/nvm.sh" ] ; then
        echo 'source "/home/linuxbrew/.linuxbrew/opt/nvm/nvm.sh"  # This loads nvm'
    fi
    if [ -s "$NVM_DIR/bash_completion" ] ; then
        # shellcheck disable=SC2016
        echo 'source "$NVM_DIR/bash_completion"  # This loads nvm bash_completion'
    elif [ -s "/home/linuxbrew/.linuxbrew/opt/nvm/etc/bash_completion.d/nvm" ] ; then
        echo 'source "/home/linuxbrew/.linuxbrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion'
    fi
fi
