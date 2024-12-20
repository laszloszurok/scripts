#!/usr/bin/env bash

fzfwrap() {
    fzfcmd="fzf --scheme=history --no-preview"
    max_recent=20 # Number of recent commands to track

    config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/fzfrun"
    cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/fzfrun"
    recent_cache="$cache_dir/recent"
    all_cache="$cache_dir/all"

    mkdir -p "$cache_dir"
    mkdir -p "$config_dir"
    touch "$recent_cache"

    update_cache() {
        echo -e \
            "$1\n$(sed "\|$1|d" "$recent_cache" | head -n "$max_recent")" \
            > "$recent_cache"
    }

    known_types=("background" "terminal" "terminal_hold")

    # get every executable on path with bash compgen
    # and write the list to $all_cache
    grep \
        --fixed-strings \
        --line-regexp \
        --invert-match \
        --file <(compgen -A function -abk) <(compgen -c) \
        > "$all_cache"

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
        while [ -n "$type" ] && ! echo "${known_types[@]}" | grep -qw "$type"; do
            { read -r query && read -r choice; } <<< \
                "$(printf "%s\n" "${known_types[@]}" | $fzfcmd --print-query)"

            # ignore invalid user input
            if [ -n "$query" ] && [ -z "$choice" ]; then
                continue
            fi

            type="$choice"
        done
        echo "$cmd_sel" >> "$config_dir/$type"
        printf "%s" "$type"
    }

    if [ -n "$cmd_sel" ] && [[ "$cmd_all" =~ $cmd_sel ]]; then
        # if $cmd_sel does not already have a type, call get_type
        # otherwise use the existing type
        if type=$(! grep -lx "$cmd_sel" -R "$config_dir"); then
            type=$(get_type)
        else
            type=${type##*/}
            # if the existing type is not in known_types, call get_type
            # and remove the invalid type
            if ! echo "${known_types[@]}" | grep -qw "$type"; then
                rm "$config_dir/$type"
                type=$(get_type)
            fi
        fi

        if [ -n "$type" ]; then
            notify-send "Launching $cmd_sel"
            update_cache "$cmd_sel"

            if [ "$type" = "background" ]; then
                setsid -f "$cmd_sel" &> /dev/null
            elif [ "$type" = "terminal" ]; then
                setsid -f kitty --class "$cmd_sel" "$cmd_sel"
            elif [ "$type" = "terminal_hold" ]; then
                setsid -f kitty --class "$cmd_sel" sh -c "$cmd_sel && echo Press Enter to kill me... && read line"
            fi
        fi
    fi
}

export -f fzfwrap

kitty \
    --class float \
    bash -c fzfwrap
