#!/bin/sh

invoke() {
    echo "$@"
    "$@"
}

instfont() {
    DEST="$1"
    shift
    invoke sudo mkdir -p "$DEST"
    invoke sudo cp "$@" "$DEST"
}

cd `dirname $0`
instfont /usr/share/fonts/opentype/source-code-pro source-code-pro/OTF/*.otf
instfont /usr/share/fonts/truetype/source-code-pro source-code-pro/TTF/*.ttf

sudo fc-cache -f -v

