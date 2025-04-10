#!/bin/sh

# lazygit single instance in zellij

if [ -z "$ZELLIJ_SESSION_NAME" ]; then
    lazygit "$@"
else
    killall lazygit
    zellij action go-to-tab-name lazygit
    zellij action write-chars "lazygit --path $PWD"
    zellij action write 13
fi
