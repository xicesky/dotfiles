#!/bin/bash

if [[ -d "$BASH_DOTDIR" && -x "$BASH_DOTDIR/.bash_logout" ]] ; then
    . "$BASH_DOTDIR/.bash_logout"
fi
