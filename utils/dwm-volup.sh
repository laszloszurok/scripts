#!/bin/sh

# Use 'pactl list sinks' to get sink names
pamixer --increase 5
kill -37 $(pidof dwmblocks)
