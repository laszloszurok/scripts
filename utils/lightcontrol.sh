#!/bin/sh

if [ "$1" = "inc" ]; then
    brightnessctl set +5%
elif [ "$1" = "dec" ]; then
    brightnessctl set 5%-
fi

blpct=$(echo "scale=2; $(brightnessctl get) / 255 * 100" \
    | bc | cut -f1 -d '.')

notify-send \
    "Brightness: $blpct%" \
    -h int:value:"$blpct" \
    --replace-id 9083
