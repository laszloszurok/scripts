#!/bin/sh

# This script is a dmenu_run wrapper with history functionality. 
# If the string 'sudo' is provided as the first argument and 
# $SUDO_ASKPASS is set, the selected program will be executed 
# with sudo -A.

terminal="alacritty.sh"
font="monospace 12"

#[ "$1" = "sudo" ] && prompt="[sudo] run:" || prompt=" run:"
[ "$1" = "sudo" ] && prompt="[sudo] run:" || prompt="run:"
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

max_recent=200 # Number of recent commands to track

config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/dmenu_hist"
cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/dmenu_hist"
recent="$cache_dir/recent"
all="$cache_dir/all"

mkdir -p "$cache_dir"
mkdir -p "$config_dir"
touch "$recent"

known_types=" background terminal terminal_hold "

IFS=:
if stest -dqr -n "$all" $PATH 2>/dev/null; then
    stest -flx $PATH | sort -u > "$all"
fi

# remove non-existent (uninstalled) programs from recent cache
while IFS= read -r line; do
    line=$(echo $line  | head -n1 | cut -d " " -f1)
    if ! which "$line" > /dev/null ; then
        sed -i "\|$line|d" "$recent"
    fi
done < "$recent"

unset IFS

# deduplicated command list
list=$(awk '!visited[$0]++' "$recent" "$all")

cmd=$(printf "%s\n" "$list" | menu_cmd -p "$prompt" ) || exit

if ! grep -qx "$cmd" "$recent" > /dev/null 2>&1; then
    grep -vx "$cmd" "$all" > "$all.$$"
    if [ -s "$all.$$" ]; then
        mv "$all.$$" "$all"
    else
        rm "$all.$$"
    fi
fi

case $cmd in
    '[') 
        exit
        ;; 
    *)
        echo "$cmd" > "$recent.$$"
        grep -vx "$cmd" "$recent" | head -n "$max_recent" >> "$recent.$$"
        mv "$recent.$$"  "$recent"
        ;;
esac

# Figure out how to run the command based on the command name, disregarding
# arguments, if any.
word0=${cmd%% *}
match="^$word0$"

get_type () {
    while type=$(echo "$known_types" | xargs -n1 | menu_cmd -p type:); do
        test "${known_types#*$type}" != "$known_types" || continue
        echo "$word0" >> "$config_dir/$type"
        break
    done
    printf "%s" "$type"
}

if ! type=$(grep -lx "$match" -R "$config_dir"); then
    type=$(get_type)
else 
    type=${type##*/}
    if ! [ "${known_types#*$type}" != "$known_types" ]; then
        rm "$config_dir/$type"
        type=$(get_type)
    fi
fi

run_as_sudo() {
    [ "$type" = "background" ] && sudo -A $cmd
    [ "$type" = "terminal" ] && sudo -A $terminal -t "$cmd" -e $cmd
    [ "$type" = "terminal_hold" ] &&
        exec sudo -A $terminal -t "$cmd" -e sh -c "$cmd && echo Press Enter to quit... && read line"
}

run_as_normal() {
    [ "$type" = "background" ] && $cmd
    [ "$type" = "terminal" ] && $terminal -t "$cmd" -e $cmd
    [ "$type" = "terminal_hold" ] &&
        exec $terminal -t "$cmd" -e sh -c "$cmd && echo Press Enter to kill me... && read line"
}

# If the firts argument is the string 'sudo' and $SUDO_ASKPASS is set,
# run the selected program as sudo. Otherwise run with normal privileges.
if [ "$1" = "sudo" ]; then
    if [ -n "$SUDO_ASKPASS" ]; then
        run_as_sudo
    else
        echo "\$SUDO_ASKPASS is not set, running with normal privileges"
        run_as_normal
    fi
else
    run_as_normal
fi
