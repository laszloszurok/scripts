#!/bin/sh

if [ "$1" = "inc" ]; then
    pamixer --increase 5
elif [ "$1" = "dec" ]; then
    pamixer --decrease 5
elif [ "$1" = "mute" ]; then
    pamixer --toggle-mute
elif [ "$1" = "micmute" ]; then
    pamixer --default-source --toggle-mute
fi

volpct=$(pamixer --get-volume)
muted=$(pamixer --get-mute)

if [ "$muted" = "false" ]; then
    notify-send \
        "Volume: $volpct%" \
        -h int:value:"$volpct" \
        --replace-id 84929
else
    notify-send \
        "Muted ($volpct%)" \
        -h int:value:"$volpct" \
        --replace-id 84929
fi
