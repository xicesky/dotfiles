#!/bin/bash
# ~/.bashrc: executed by bash(1) for non-login shells.

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

export BASH_DOTDIR=~/.config/bash
. "$BASH_DOTDIR/.bashrc"
