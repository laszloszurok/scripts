#!/bin/bash

dirs=$(ls -d -- */)
printf "%s\n" "$dirs"

for dir in $dirs; do
    sub_name=${dir%/}
    cp "$dir$1"2* ./"$sub_name.srt"
done
