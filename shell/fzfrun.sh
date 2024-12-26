#!/bin/sh

set -o errexit

fzfcmd="fzf --scheme=history --no-preview"
max_recent=100 # Number of recent commands to track
config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/fzfrun"
cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/fzfrun"
recent_cache="$cache_dir/recent"
all_cache="$cache_dir/all"
known_types="background terminal terminal_hold"
mkdir -p "$cache_dir"
mkdir -p "$config_dir"
touch "$recent_cache"

update_cache() {
    printf '%s\n%s' "$1" "$(sed "\|$1|d" "$recent_cache" | head -n "$max_recent")" > "$recent_cache"
}

# get every executable on path and write the list to $all_cache
set +o errexit
# shellcheck disable=SC2086
(IFS=:; find $PATH -maxdepth 1 -executable \( -type f -o -type l \) -printf '%f\n' 2> /dev/null > "$all_cache")
set -o errexit

# remove anything from recent_cache that is not present in all_cache
grep \
    --invert-match \
    --line-regexp \
    --fixed-strings \
    --file "$all_cache" \
    "$recent_cache" | \
    while read -r line; do
        sed -i "\|$line|d" "$recent_cache"
    done

# deduplicated command list
cmd_all=$(awk '!visited[$0]++' "$recent_cache" "$all_cache")

cmd_sel="$(echo "$cmd_all" | $fzfcmd)"

get_type () {
    # keep asking for $type while it is not in known_types
    type="none";
    while [ -n "$type" ] && ! echo "$known_types" | grep --silent --word-regexp "$type"; do
        fzfout=$(printf "%s\n" "$known_types" | xargs -n1 | $fzfcmd --print-query)
        query=$(echo "$fzfout" | head -n 1)
        choice=$(echo "$fzfout" | tail -n 1)

        # ignore invalid user input
        if [ -n "$query" ] && [ -z "$choice" ]; then
            continue
        fi

        type="$choice"
    done
    echo "$cmd_sel" >> "$config_dir/$type"
    printf "%s" "$type"
}

if [ -n "$cmd_sel" ] && echo "$cmd_all" | grep --silent "$cmd_sel"; then
    # if $cmd_sel does not already have a type, call get_type
    # otherwise use the existing type
    if type=$(! grep -lx "$cmd_sel" -R "$config_dir"); then
        type=$(get_type)
    else
        type=${type##*/}
        # if the existing type is not in known_types, call get_type
        # and remove the invalid type
        if ! echo "$known_types" | grep --silent --word-regexp "$type"; then
            rm "$config_dir/$type"
            type=$(get_type)
        fi
    fi

    if [ -n "$type" ]; then
        notify-send "Launching $cmd_sel"
        update_cache "$cmd_sel"

        if [ "$type" = "background" ]; then
            setsid -f "$cmd_sel" > /dev/null 2>&1
        elif [ "$type" = "terminal" ]; then
            setsid -f kitty --class "$cmd_sel" "$cmd_sel"
        elif [ "$type" = "terminal_hold" ]; then
            setsid -f kitty --class "$cmd_sel" sh -c "$cmd_sel && echo Press Enter to kill me... && read line"
        fi
    fi
fi
