#!/bin/sh

pamixer --default-source --toggle-mute
kill -36 $(pidof dwmblocks)
