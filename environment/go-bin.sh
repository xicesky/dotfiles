#!/bin/bash

# Add go binaries to path
if [[ -d "${HOME}/go/bin" ]] ; then
    append_to_path "${HOME}/go/bin"
fi
