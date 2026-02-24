#!/bin/bash

# Activate mise if installed
if MISE_EXECUTABLE="$(find_executable mise /home/linuxbrew/.linuxbrew/bin/mise)" ; then
    # Calling mise activate here directly does not work because the command likes to re-set our PATH
    # Hopefully this is just "fast enough"
    cat <<EOF
eval "\$("$MISE_EXECUTABLE" activate "$SHELL_TYPE")"
EOF
fi
