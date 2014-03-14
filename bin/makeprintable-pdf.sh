#!/bin/sh
set -e

INPUT="$1"
[ -r "$1" ] || { echo "No input file"; exit 1; }

invoke() {
    echo "$@"
    "$@"
}

invoke pdftocairo -pdf "$1" stage1.pdf

invoke gs -sDEVICE=pdfwrite \
    -sProcessColorModel=DeviceGray \
    -sColorConversionStrategy=Gray \
    -dOverrideICC \
    -o stage2.pdf \
    -f stage1.pdf

# -dPDFSETTINGS=
#   /prepress
#   /printer

invoke gs -sDEVICE=pdfwrite \
    -dPDFSETTINGS=/printer \
    -o stage3.pdf \
    -f stage2.pdf

