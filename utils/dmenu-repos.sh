#!/bin/sh

source_dir="$HOME/source"

# for remembering history
cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/repolist"
recent="$cache_dir/recent"
all="$cache_dir/all"
mkdir -p "$cache_dir"

# dmenu settings
prompt=" git repos:"
dmenu_cmd="dmenu -lh 26 -l 20 -c -i $@"

# remove the picked item from $recent, then write it in the first line
update_cache() {
    sed -i "\|$1|d" "$recent"
    printf "%s\n%s" "$1" "$(cat "$recent")" > "$recent"
}

# get all directories from $source_dir in a list
repos=$(ls "$source_dir"/* -d)

echo "$repos" > "$all" # always write all items to $all
[ ! -f "$recent" ] && echo "$repos" > "$recent" # create $recent if it doesn't exist

# remove anything from $recent that is not present in $all
for line in $(grep -vxf "$all" "$recent"); do
    sed -i "\|$line|d" "$recent"
done

# merging $recent and $all, find the first occurrence of every entry 
# and remove any other occurrences
list=$(awk '!visited[$0]++' "$recent" "$all")

# replace $HOME with ~ for every list item
list=$(echo "$list" | sed "s\\$HOME\~\g")

to_open=$(printf "%s\n" "$list" | $dmenu_cmd -p "$prompt")

# exit if the user did not pick an item
[ -n "$to_open" ] || exit

# undo the replacement for the picked item (otherwise won't open correctly)
to_open=$(echo "$to_open" | sed "s\~\\$HOME\g")

update_cache "$to_open"

$TERMINAL lazygit -p "$to_open"
