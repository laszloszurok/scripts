#!/bin/bash

fzfwrap() {
    max_recent=20 # Number of recent commands to track

    config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/fzfrun-hist"
    cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/fzfrun-hist"
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

    known_types=" background terminal terminal_hold "

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

    cmd_sel="$(echo "$cmd_all" | fzf --no-preview)"

    if [[ -n "$cmd_sel" ]] && [[ "$cmd_all" =~ $cmd_sel ]]; then
        notify-send "Launching $cmd_sel"
        update_cache "$cmd_sel"
        eval setsid -f "$cmd_sel"
    fi
}

export -f fzfwrap

alacritty \
    --option window.dimensions.columns=40 \
    --class float \
    --command bash -c fzfwrap
