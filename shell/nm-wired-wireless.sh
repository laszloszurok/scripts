#!/bin/bash

# Make NetworkManager disable wifi, when a wired connection is up and switch to wifi
# when there is no wired connection.
#
# Put this script here: /etc/NetworkManager/dispatcher.d/70-wifi-wired-exclusive.sh
# then run the following commands:
# sudo chown root:root /etc/NetworkManager/dispatcher.d/70-wifi-wired-exclusive.sh
# sudo chmod 744 /etc/NetworkManager/dispatcher.d/70-wifi-wired-exclusive.sh
# sudo systemctl restart NetworkManager

# original: https://neilzone.co.uk/2023/04/networkmanager-automatically-switch-between-ethernet-and-wi-fi/

# Add the name of your specific ethernet device here, as shown in `nmcli dev`
ETHERNET="enx806d9728435c"

if [ "$1" = "$ETHERNET" ] && [ "$2" = "up" ]; then
    if [ "$(nmcli -get-values general.state device show "$ETHERNET")" = "100 (connected)" ]; then
        nmcli radio wifi off
    fi
elif [ "$1" = "$ETHERNET" ] && [ "$2" = "down" ]; then
    nmcli radio wifi on
fi
