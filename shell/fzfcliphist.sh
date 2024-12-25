#!/bin/sh

sel=$(cliphist list | fzf --no-preview -d '\t' --with-nth 2)
if [ -n "$sel" ]; then
    printf "%s" "$sel" | cliphist decode | wl-copy
fi
