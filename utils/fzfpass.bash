#!/bin/bash

fzfwrap() {
    shopt -s nullglob globstar

    # files to work with
    cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/fzfpass"
    recent_cache="$cache_dir/recent"
    all_cache="$cache_dir/all"

    mkdir -p "$cache_dir"

    # Insert the picked entry to the first line of the cache file
    # and remove any other occurrences. This way the last picked
    # entry will always be the first in the list.
    update_cache() {
        echo -e "$1\n$(sed "\|$1|d" "$recent_cache")" > "$recent_cache"
    }
    # merging $recent and $all, find the first occurrence of every entry 
    # and remove any other occurrences
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

    list=$(awk '!visited[$0]++' "$recent_cache" "$all_cache")

    pass_sel="$(printf '%s\n' "$list" | fzf --scheme=history --no-preview)"

    if [[ -n "$pass_sel" ]] && [[ "${password_files[*]}" =~ $pass_sel ]]; then
        notify-send "Copying $pass_sel"
        pass -c "$pass_sel"
        update_cache "$pass_sel"
    fi
}

export -f fzfwrap

alacritty \
    --class float \
    --command bash -c fzfwrap
