#!/bin/sh

# Rust wants to do:
# . "$HOME/.cargo/env"
# Which contains the following:

# affix colons on either side of $PATH to simplify matching
#case ":${PATH}:" in
#    *:"$HOME/.cargo/bin":*)
#        ;;
#    *)
#        # Prepending path in case a system-installed rustc needs to be overridden
#        export PATH="$HOME/.cargo/bin:$PATH"
#        ;;
#esac

# But we just want to add $HOME/.cargo/bin to the path
if [[ -d $HOME/.cargo/bin ]] ; then
    append_to_path "${HOME}/.cargo/bin"
fi
