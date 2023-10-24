#!/bin/bash

yt_url="$1"

IFS=$'\n'

for line in $(yt-dlp \
    --write-comments \
    --dump-single-json "$yt_url" \
    | jq '.comments[].text')
do
    echo -e "$line\n"
done | bat --paging=always --style=numbers
