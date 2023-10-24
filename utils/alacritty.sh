#!/bin/sh

if pidof "alacritty"; then
    setsid -f alacritty msg create-window "$@"
else
    setsid -f alacritty "$@"
fi
