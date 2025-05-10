#!/bin/bash

# Just add the snap bin directory to the path
if [[ -d /snap/bin ]] ; then
    append_to_path "/snap/bin"
fi
