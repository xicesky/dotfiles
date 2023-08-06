#!/bin/bash

if ismingw || ismsys ; then

    # on mingw/msys we need to augment autocompletion for windows drives
    # thanks, https://github.com/msys2/MSYS2-packages/issues/38#issuecomment-150131217
    if [[ "$SHELL_TYPE" = "zsh" ]] ; then
        cat <<"EOF"
drives=$(mount | sed -rn 's#^[A-Z]: on /([a-z]).*#\1#p' | tr '\n' ' ')
zstyle ':completion:*' fake-files /: "/:$drives"
unset drives
EOF
    fi

fi
