#!/bin/sh

blpct=$(brightnessctl | grep -E '[0-9]{2}%' -o | sed 's/.$//')

notify-send \
    "Brightness: $blpct%" \
    -h int:value:"$blpct" \
    --replace-id 9083
