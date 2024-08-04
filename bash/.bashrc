#!/bin/bash
# ~/.bashrc: executed by bash(1) for non-login shells.

# Unset SHELL_TYPE and SKY_ENVIRONMENT_FILE, they might come from another shell
SHELL_TYPE=""
SKY_ENVIRONMENT_FILE=""

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

export BASH_DOTDIR=~/.config/bash
. "$BASH_DOTDIR/.bashrc"
