#
# color: Make the terminal more colorful.
#

# Return if requirements are not found.
[[ "$TERM" != 'dumb' ]] || return 1

# Built-in zsh colors.
autoload -Uz colors && colors

# Colorize completions.
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}

# Mark this plugin as loaded.
zstyle ':zephyr:plugin:color' loaded 'yes'
