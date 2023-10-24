#!/bin/sh

# Use 'pactl list sinks' to get sink names
pamixer --decrease 5
kill -37 $(pidof dwmblocks)
