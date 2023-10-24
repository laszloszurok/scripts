#!/bin/sh

notify-send 'Loading...'
mpv > /dev/null 2>&1 "$1" || notify-send 'Failed to load video'
