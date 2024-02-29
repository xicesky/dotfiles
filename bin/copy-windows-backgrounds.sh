#!/bin/bash

# Resolve windows LOCALAPPDATA path
function resolve_local_app_data() {
    if which cygpath &>/dev/null; then
        # Cygwin & msys
        cygpath -u "$LOCALAPPDATA"
    elif which wslvar &>/dev/null; then
        wslpath -u "$(wslvar LOCALAPPDATA)"
    else
        echo "Error: Could not resolve LOCALAPPDATA path" 1>&2
        return 1
    fi
}

lapdata="$(resolve_local_app_data)" || exit 1
[[ -d "$lapdata" ]] || { echo "Error: Could not find LOCALAPPDATA directory" 1>&2; exit 1; }

picturedir="$lapdata/Packages/Microsoft.Windows.ContentDeliveryManager_cw5n1h2txyewy/LocalState/Assets"
ff "$picturedir" -type f \
    | while IFS= read -r file; do
    dest="./$(basename "$file").jpeg"
    [[ -e "$dest" ]] && continue
    cp -v "$file" "$dest"
done
