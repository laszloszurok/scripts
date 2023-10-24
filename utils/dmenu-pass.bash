#!/bin/bash

# This script is a modified version of the original passmenu script which is part
# of the pass program. This script has history functionality, which means when you
# open up the password picker the entries will be listed in the order you last used
# them.

shopt -s nullglob globstar

# dmenu settings
font="monospace 12"
#prompt=" copy:"
prompt="copy:"
menu_cmd() {
    if [ "$XDG_SESSION_TYPE" = "wayland" ]; then
        bemenu \
            --fn "$font" \
            --center \
            --list 20 \
            --line-height 26 \
            --width-factor 0.2 \
            --ch 15 \
            --cw 2 \
            --nf "#e0dbd2" \
            --nb "#191b28" \
            --ab "#191b28" \
            --hb "#563d7c" \
            --hf "#e0dbd2" \
            --tf "#e0dbd2" \
            --tb "#3e4050" \
            --fb "#2a2c39" \
            --ignorecase \
            --no-spacing \
            "$@"
    else
        dmenu \
            -lh 26 \
            -l 20 \
            -c \
            -i \
            "$@"
    fi
}

# files to work with
cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/passmenu_hist"
recent_cache="$cache_dir/recent"
all_cache="$cache_dir/all"

mkdir -p "$cache_dir"

# Insert the picked entry to the first line of the cache file
# and remove any other occurrences. This way the last picked
# entry will always be the first in the list.
update_cache() {
    sed -i "\|$1|d" "$recent_cache"
    echo -e "$1\n$(< "$recent_cache")" > "$recent_cache"
}

# get the full list of password entries from the password store
prefix=${PASSWORD_STORE_DIR-~/.password-store}
password_files=( "$prefix"/**/*.gpg )
password_files=( "${password_files[@]#"$prefix"/}" )
password_files=( "${password_files[@]%.gpg}" )

# write to recent_cache if it does not exist
[ ! -f "$recent_cache" ] && echo "${password_files[@]}" | tr " " "\n" > "$recent_cache"

# always write the full list to all_cache, so the list will be always up to date
echo "${password_files[@]}" | tr " " "\n" > "$all_cache"

# remove anything from recent_cache that is not present in all_cache (eg. the user deleted an entry from the password-store)
grep -vxf "$all_cache" "$recent_cache" | while read -r line; do
    sed -i "\|$line|d" "$recent_cache"
done 

# merging $recent and $all, find the first occurrence of every entry 
# and remove any other occurrences
list=$(awk '!visited[$0]++' "$recent_cache" "$all_cache")

# pipe the list into dmenu to show the password picker
entry=$(printf '%s\n' "$list" | menu_cmd -p "$prompt" "$@")

# check if the user picked an entry, exit if didn't
[[ -n $entry ]] || exit

# update the cache with the picked entry
update_cache "$entry"

pass show -c "$entry" 2>/dev/null && notify-send "Passmenu" "copied $entry"
