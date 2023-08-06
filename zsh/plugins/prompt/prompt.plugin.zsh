
autoload -Uz promptinit && promptinit

# Set the prompt if specified
local -a prompt_argv
zstyle -a ':zephyr:plugin:prompt' theme 'prompt_argv'
if [[ $TERM == (dumb|linux|*bsd*) ]]; then
  prompt 'off'
elif (( $#prompt_argv > 0 )); then
  prompt "$prompt_argv[@]"
fi
unset prompt_argv
