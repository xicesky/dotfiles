#!/bin/bash

# Set GIT_SSH so jgitflow-maven-plugin doesn't use jsch and fail with "Algorithm negotiation fail"
# See https://www.eclipse.org/forums/index.php/t/1092406/
cat <<"EOF"
export GIT_SSH="$(which ssh)"
EOF
