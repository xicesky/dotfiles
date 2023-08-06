#!/bin/bash

# FIXME: Should just be incorporated here directly
if [[ -e "${HOME}/bin/my-ssh-pageant.sh" ]] ; then
    # shellcheck disable=SC2016
    echo 'eval $(${HOME}/bin/my-ssh-pageant.sh)'
fi

cat <<"EOF"
# gpg tty - see man 1 gpg-agent
GPG_TTY=$(tty)
export GPG_TTY
EOF
