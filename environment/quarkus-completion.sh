#!/bin/bash

# quarkus autocompletion
# FIXME: should check discovered path for these binaries
if which java 2>/dev/null 1>&2 && which quarkus 2>/dev/null 1>&2 ; then
    quarkus completion
fi
