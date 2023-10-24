#!/bin/sh

blpct=$(echo "scale=2; $(brightnessctl get) / 255 * 100" \
    | bc | cut -f1 -d '.')

notify-send \
    "Brightness: $blpct%" \
    -h int:value:"$blpct" \
    --replace-id 9083
