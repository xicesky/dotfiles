#!/bin/bash

# XDG
echo "export XDG_CONFIG_HOME=\${XDG_CONFIG_HOME:-~/.config}"
echo "export XDG_CACHE_HOME=\${XDG_CACHE_HOME:-~/.cache}"
echo "export XDG_DATA_HOME=\${XDG_DATA_HOME:-~/.local/share}"
echo "export XDG_STATE_HOME=\${XDG_STATE_HOME:-~/.local/state}"
echo "export XDG_RUNTIME_DIR=\${XDG_RUNTIME_DIR:-~/.xdg}"
#echo "export XDG_PROJECTS_DIR=~/Projects"
