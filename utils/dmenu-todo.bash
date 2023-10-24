#!/bin/bash

dmenu_cmd="dmenu -lh 26 -l 20 -c -i"
prompt="todo options:"
terminal="st"
editor="nvim"

data_dir=~/.local/share/dmenu-todo
[ ! -d "$data_dir" ] && mkdir -p "$data_dir"

todo_dir="$data_dir/todos"
[ ! -d "$todo_dir" ] && mkdir -p "$todo_dir"

todo_metadata_file="$data_dir/todos.metadata"
[ ! -f "$todo_metadata_file" ] && touch "$todo_metadata_file"

options=( "list todos" "add new todo" )

list_todos() {
    local todos
    local todo
    local todo_path
    local action
    local prompt
    local new_title
    local new_path

    todos=$(head -q -n 1 "$todo_dir"/*)
    #todos=$(cut -s -f 2- -d ' ' "$todo_metadata_file")
    prompt="todo list:"

    while todo=$(printf "%s\n" "$todos" | $dmenu_cmd -p "$prompt"); do
        todo_path=$(grep "$todo" "$todo_metadata_file" | cut -f 1 -d ' ')

        if [ -f "$todo_path" ]; then
            action=$(list_todo_options)
            if [ "$action" = "edit" ]; then
                $terminal -e $editor "$todo_path"
                new_title=$(head -q -n 1 "$todo_path")
                new_path="$todo_dir/$(generate_filename "$new_title")"
                mv "$todo_path" "$new_path"
                sed -i "s|$todo_path $todo|$new_path $new_title|g" "$todo_metadata_file"
            elif [ "$action" = "delete" ]; then
                rm "$todo_path"
                sed -i /"$todo"/d "$todo_metadata_file"
            fi
        fi

        todos=$(head -q -n 1 "$todo_dir"/*)
        #todos=$(cut -s -f 2- -d ' ' "$todo_metadata_file")
    done
}

list_todo_options() {
    local prompt
    local action
    local options

    prompt="todo options:"
    options=( "edit" "delete" )

    while action=$(printf "%s\n" "${options[@]}" | $dmenu_cmd -p "$prompt"); do
        # loop until the user types a valid option
        if [[ ! "${options[*]}" =~ "${action}" ]]; then
            continue
        fi
        break
    done

    printf "%s\n" "$action"
}

generate_filename() {
    local str="$1"
    local filename="${str// /-}"
    filename="${filename////_}"
    printf "%s\n" "$filename"
}

create_todo() {
    local todo
    local todo_path
    local filename
    local prompt

    prompt="todo:"
    todo=$(printf '' | $dmenu_cmd -p "$prompt")
    todo_path=$(grep "$todo" "$todo_metadata_file" | cut -f 1 -d ' ')

    if [ -n "$todo" ] && [ ! -f "$todo_path" ]; then
        filename=$(generate_filename "$todo")
        printf "%s\n" "$todo" >> "$todo_dir/$filename"
        printf "%s %s\n" "$todo_dir/$filename" "$todo" >> "$todo_metadata_file"
    else
        printf "a todo with that name alredy exists\n"
    fi
}

while action=$(printf "%s\n" "${options[@]}" | $dmenu_cmd -p "$prompt") || exit; do
    if [ "$action" = "list todos" ]; then
        list_todos
    elif [ "$action" = "add new todo" ]; then
        create_todo
    fi
done
