#!/bin/sh

fzfparams="--scheme=history --no-preview"
cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/fzfpass"
recent_cache="$cache_dir/recent"
all_cache="$cache_dir/all"
mkdir -p "$cache_dir"

# process commandline options
eval set -- "$(getopt --options 'hs' --long 'help,show,height:' --name 'fzfpass.bash' -- "$@")"
while true; do
	case "$1" in
		'-h'|'--help')
            usage
            exit 0
		;;
		'-s'|'--show')
			show="true"
			shift
			continue
		;;
		'--height')
			fzfparams="$fzfparams --height=$2"
			shift 2
			continue
		;;
		'--')
			shift
			break
		;;
		*)
			echo 'Internal error!' >&2
			exit 1
		;;
	esac
done

usage() {
    echo "Usage:
  fzfpass.bash [OPTIONS]

Options:
  -h, --help - Display this message
  -s, --show - Only show the selected item instead of copying it
  --height HEIGHT - set the height of the fzf UI to HEIGHT
"
}

# Write the selected item to the first line of the cache file
# and remove any other occurrences. This way the last picked
# item will always be the first in the list.
update_cache() {
    printf '%s\n%s\n' "$1" "$(sed "\|$1|d" "$recent_cache")" > "$recent_cache"
}

# get all the names of the entries in the password-store without the .gpg extension
IFS=$(printf '\n')
prefix=${PASSWORD_STORE_DIR-~/.password-store}
password_files=$(find "$prefix" -name "*.gpg" | sed -e "s|$prefix/||g" -e 's|\.gpg$||')
unset IFS

# write to recent_cache if it does not exist
[ ! -f "$recent_cache" ] && echo "$password_files" > "$recent_cache"

# always write the full list to all_cache, so the list will be always up to date
echo "$password_files" > "$all_cache"

# remove anything from recent_cache that is not present in all_cache (eg. the user deleted an item from the password-store)
grep -vxf "$all_cache" "$recent_cache" | while read -r line; do
    sed -i "\|$line|d" "$recent_cache"
done

list=$(awk '!visited[$0]++' "$recent_cache" "$all_cache")

# shellcheck disable=SC2086
pass_sel="$(printf '%s\n' "$list" | fzf $fzfparams)"

if [ -n "$pass_sel" ] && echo "$password_files" | grep --silent "$pass_sel"; then
    if [ "$show" = "true" ]; then
        echo "$pass_sel"
        pass show "$pass_sel"
    else
        notify-send "Copying $pass_sel" > /dev/null 2>&1
        pass -c "$pass_sel"
    fi
    update_cache "$pass_sel"
fi
