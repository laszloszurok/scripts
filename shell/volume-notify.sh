#!/bin/sh

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
