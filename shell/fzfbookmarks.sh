#!/bin/sh

bookmark_file="$HOME/.local/share/bookmarks"

kitty \
    --class float \
    sh -i -c "
        sel=\$(tac $bookmark_file | fzf --no-preview | awk '{print \$NF}')
        xdg-open \$sel &
    "
