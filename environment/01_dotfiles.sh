#!/bin/bash
SKY_DOTFILES="$(dirname "$SRC_DIR")"
export SKY_DOTFILES
echo "export SKY_DOTFILES=$(printf "%q" "$SKY_DOTFILES")"
ADDITIONAL_PATH+=( "$SKY_DOTFILES/bin" )
