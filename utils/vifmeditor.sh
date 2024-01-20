#!/bin/sh

# I set this script in vifmrc as vicmd, so when a file is opend,
# a new neovim remote will be launched, if there is not one alredy.
# Otherwise the file will be opend in the existing instance.

if [ -z "$DISPLAY" ] && [ -z "$WAYLAND_DISPLAY" ]; then
    nvim "$@"
else
    if [ -f /tmp/nvr-socket ]; then
        nvr --servername=/tmp/nvr-socket "$@" > /dev/null 2>&1
    else
        setsid -f $TERMINAL -e nvr --servername=/tmp/nvr-socket "$@" > /dev/null 2>&1
    fi
fi
