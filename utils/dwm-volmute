#!/bin/sh

# Use 'pactl list sinks' to get sink names
pamixer --set-volume 20
pamixer --toggle-mute
kill -37 $(pidof dwmblocks)
