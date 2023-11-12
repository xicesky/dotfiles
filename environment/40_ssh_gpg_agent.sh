#!/bin/bash

# Generate a function to load the ssh agent background process (if it
#   isn't loaded yet)
# FIXME: Should just be incorporated here directly if possible

cat <<"EOF"
load-ssh-agent() {
    if [[ -e "${HOME}/bin/my-ssh-agent.eval.sh" ]] ; then
        # shellcheck disable=SC2016
        eval "$(${HOME}/bin/my-ssh-agent.eval.sh)"
    fi
}
EOF

# Set stuff for gpg

cat <<"EOF"
# gpg tty - see man 1 gpg-agent
GPG_TTY=$(tty)
export GPG_TTY
EOF
