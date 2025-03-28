#!/bin/bash

# select kubectl context with fzf

fzfcmd="fzf --scheme=history --no-preview --height=10"
max_recent=20 # Number of recent commands to track

cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/fzfkube"
recent_cache="$cache_dir/recent"
all_cache="$cache_dir/all"

mkdir -p "$cache_dir"
touch "$recent_cache"

update_cache() {
    echo -e \
        "$1\n$(sed "\|$1|d" "$recent_cache" | head -n "$max_recent")" \
        > "$recent_cache"
}

kubectl config get-contexts -o name > "$all_cache"

# remove anything from recent_cache that is not present in all_cache
sed -i '/^[[:space:]]*$/d' "$recent_cache"
grep \
    --invert-match \
    --line-regexp \
    --fixed-strings \
    --file "$all_cache" \
    "$recent_cache" | \
    while read -r line; do
        sed -i "\|$line|d" "$recent_cache"
    done

# deduplicated list
contexts=$(awk '!visited[$0]++' "$recent_cache" "$all_cache")

ctx="$(echo "$contexts" | $fzfcmd)"

if [ -n "$ctx" ]; then
    update_cache "$ctx"
    echo "$ctx" | xargs kubectl config use-context
fi
