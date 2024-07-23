#!/bin/sh

alacritty \
    --class float \
    --command sh -c "
        sel=\"\$(tac \"$HOME/.local/share/mpv-history/history.log\" | awk '!x[\$0]++' | fzf --no-preview | awk '{print \$NF}')\"
        if [ -n \"\$sel\" ]; then
            notify-send \"Loading...\"
            setsid -f mpv \"\$sel\" || notify-send \"Failed to load video\"
        fi
    "
