#!/bin/bash

# Load gvm (Go Version Manager): https://github.com/moovweb/gvm
if [[ -s "$HOME/.gvm/scripts/gvm" ]] ; then
    # shellcheck disable=SC2016
    echo 'source "$HOME/.gvm/scripts/gvm"'
fi
