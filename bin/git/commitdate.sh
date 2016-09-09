#!/bin/sh

D=`date -v-20d +%FT%H:%M:%S%z`
echo "$D"

GIT_AUTHOR_DATE="$D" GIT_COMMITTER_DATE="$D" git commit
