#!/bin/bash

# This script shows the output of the cal -y command in the terminal.
# The output will be written in a file, then the content of the file
# will be displayed on the screen centered and the script waits for
# a keypress to quit. I use it to show a calendar when I right click
# the clock in  my statusbar

[ ! -d "$HOME/.cache/calendar" ] && mkdir $HOME/.cache/calendar

date="$(date '+%a %d %b')"
echo "Current date: $date" > $HOME/.cache/calendar/cal.txt
cal -my >> $HOME/.cache/calendar/cal.txt
echo "
Press any key to exit" >> $HOME/.cache/calendar/cal.txt

display_center(){
    columns="$(tput cols)"
    while IFS= read -r line; do
        printf "%*s\n" $(( (${#line} + columns) / 2)) "$line"
    done < "$1"
}

display_center "$HOME/.cache/calendar/cal.txt"

if [ -t 0 ]; then
   old_tty=$(stty --save)
   stty raw -echo min 0
fi
while
   IFS= read -r REPLY
   [ -z "$REPLY" ]
do
sleep 0.1
done
if [ -t 0 ]; then stty "$old_tty"; fi
