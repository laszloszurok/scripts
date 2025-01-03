#!/bin/sh

# launch youtube music in a separate qutebrowser session

set -- "${@}" --basedir ~/.local/share/qutebrowser-ytm
set -- "${@}" --config-py ~/.config/qutebrowser/config.py
set -- "${@}" --target window
set -- "${@}" --set tabs.show never
set -- "${@}" --set statusbar.show in-mode
set -- "${@}" --set window.title_format youtube-music
set -- "${@}" --set auto_save.session false

qutebrowser music.youtube.com "${@}"
