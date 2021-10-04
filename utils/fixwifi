#!/bin/sh

# some wireless cards do not use the right antenna settings by default, so i have to run this to have normal wifi signal strength
sudo modprobe -r rtl8723de && sleep 5 && sudo modprobe rtl8723de ant_sel=2
