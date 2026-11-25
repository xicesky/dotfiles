#!/bin/bash

# Load SDKMAN https://sdkman.io/
if [[ -d "$HOME/.sdkman" ]] ; then
    # shellcheck disable=SC2016
    echo 'export SDKMAN_DIR="$HOME/.sdkman"'
    if [[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] ; then
        # shellcheck disable=SC2016
        echo 'source "$HOME/.sdkman/bin/sdkman-init.sh"'
    fi
fi
