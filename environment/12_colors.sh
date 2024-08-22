#!/bin/bash

if which dircolors >/dev/null && [[ -n "$SKY_DOTFILES" ]] ; then
    dircolors -b "$SKY_DOTFILES/colors/.dircolors"
fi
