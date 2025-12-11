#!/bin/bash

# Add python user path (mostly osx?)
if [[ -d ~/Library/Python ]] ; then
    while IFS= read -r -d $'\0' i ; do
        path+=~/Library/Python/$i/bin
    done < <(
        $FIND ~/Library/Python -mindepth 1 -maxdepth 1 -type d -printf "%f\0" | $SORT -z --version-sort -r
    )
fi

# Pipenv install according to https://pipenv.pypa.io/en/latest/installation.html
if [[ -d "$HOME/.pipenv-venv/bin" ]] ; then
    export_variable PIPENV_IGNORE_VIRTUALENVS 1
    append_to_path "$HOME/.pipenv-venv/bin"
fi
