#!/bin/sh

touch -t `date -v-20d +%Y%m%d%H%M` "$@"
