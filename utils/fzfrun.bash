#!/bin/bash

fzfwrap() {
    cmd_all=$(compgen -c)
    cmd_sel="$(echo "$cmd_all" | fzf --no-preview)"
    if [[ "$cmd_all" =~ $cmd_sel ]]; then
        notify-send "Launching $cmd_sel"
        eval setsid -f "$cmd_sel"
    fi
}

export -f fzfwrap

alacritty --class float -e bash -c fzfwrap
