#!/bin/bash

# FIXME: Should just be incorporated here directly if possible

# OLD ssh-pageant behaviour - DEPRECATED
# if [[ -e "${HOME}/bin/my-ssh-pageant.sh" ]] ; then
#     # shellcheck disable=SC2016
#     echo 'eval $(${HOME}/bin/my-ssh-pageant.sh)'
# fi

# NEW behaviour: Use eval script from _dotfiles/ssh/ssh-agent-scripts
if [[ -e "${HOME}/bin/my-ssh-agent.eval.sh" ]] ; then
    # shellcheck disable=SC2016
    echo 'eval $(${HOME}/bin/my-ssh-agent.eval.sh)'
fi

cat <<"EOF"
# gpg tty - see man 1 gpg-agent
GPG_TTY=$(tty)
export GPG_TTY
EOF
