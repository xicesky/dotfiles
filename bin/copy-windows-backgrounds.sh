#!/bin/bash

lapdata="$(cygpath -u "$LOCALAPPDATA")"
picturedir="$lapdata/Packages/Microsoft.Windows.ContentDeliveryManager_cw5n1h2txyewy/LocalState/Assets"
ff "$picturedir" -type f \
    | while IFS= read -r file; do
    dest="./$(basename "$file").jpeg"
    [[ -e "$dest" ]] && continue
    cp -v "$file" "$dest"
done

