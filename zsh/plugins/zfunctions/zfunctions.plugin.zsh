# Partially from https://github.com/mattmc3/zephyr/tree/main/plugins/zfunctions
# With some heavy modifications to avoid problems with empty directories

##? zfunctions - Use a Fish-like functions directory for zsh functions.

function load_function_directory() {
  declare opts=""
  if [[ "$1" == -* ]] ; then opts="$1"; shift; fi
  if [[ "$opts" == *p* ]] ; then
    fpath=("$1" $fpath)   # prepend to fpath
  else
    fpath+=("$1")         # append to fpath
  fi
  # autoload files, if any
  declare -a files
  # TODO: zsh can probably do this with some smart filename expansion
  #   see https://zsh.sourceforge.io/Doc/Release/Expansion.html#Filename-Generation
  files=( "${(@0)$(find "$1" -maxdepth 1 -iname . -o -iname .. -o -type f -print0)}" ); files[-1]=()
  if [[ $#files -gt 0 ]] ; then
    autoload -Uz "$files[@]"
  fi
}

# Load plugins functions.
load_function_directory -p "${0:A:h}/functions"

# Load zfunctions.
if [[ -z "$ZFUNCDIR" ]]; then
  ZFUNCDIR=${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config/zsh}}/functions
fi
[[ -d "$ZFUNCDIR" ]] || return
load_function_directory -p "$ZFUNCDIR"

# Load zfunctions subdirs.
for _fndir in $ZFUNCDIR(N/) $ZFUNCDIR/*(N/); do
  load_function_directory -p "$_fndir"
done
unset _fndir

# Tell Zephyr this plugin is loaded.
zstyle ":zephyr:plugin:zfunctions" loaded 'yes'
