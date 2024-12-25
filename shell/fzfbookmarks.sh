#!/bin/sh

bookmark_file="$HOME/.local/share/bookmarks"

sel=$(tac "$bookmark_file" | fzf --no-preview | awk '{print $NF}')
if [ -n "$sel" ]; then
    setsid -f xdg-open "$sel"
fi
