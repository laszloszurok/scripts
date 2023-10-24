#!/bin/sh

# Wrapper around lazygit, to check if we are in a git repo or not, before launching it.
# If we are in a git repo just launch normally, if we aren't, then open the bare repo
# in my home directory, which I use to manage dotfiles.

if git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    /usr/bin/lazygit
else
    /usr/bin/lazygit --git-dir=$HOME/.cfg --work-tree=$HOME
fi
