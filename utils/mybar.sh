#!/bin/bash

############### USER: MODIFY THESE VARIABLES ###############
readonly dwl_output_filename="$HOME"/.cache/dwltags # File to watch for dwl output
readonly labels=( "1" "2" "3" "4" "5" "6" "7" "8" "9" ) # Number of lables must match dwl's config.h tagcount
pango_tag_default="<span foreground='#555'>" # Pango span style for 'default' tags
pango_tag_active="<span>" # Pango span style for 'active' tags
pango_tag_selected="<span>" # Pango span style for 'selected' tags
pango_tag_urgent="<span foreground='#fb4934'>" # Pango span style for 'urgent' tags
pango_layout="<span>" # Pango span style for 'layout' character
pango_inactive="<span foreground='#555'>" # Pango span style for elements on an INACTIVE monitor
############### USER: MODIFY THESE VARIABLES ###############

dwl_log_lines_per_focus_change=7 # This has changed several times as dwl has developed and may not yet be rock solid
monitor="${1}"

_cycle() {
    tag_list=""

    used_tags=$(echo "obase=2; $(( activetags | selectedtags ))" | bc | numfmt --format=%09f | rev)

    for (( i=0; i<${#used_tags}; i++ )); do
        if [ "${used_tags:$i:1}" = "1" ]; then
            tag_list+="$i "
        fi
    done

    full_components_list=( $tag_list "layout") # (1, 2, ... length_of_$labels) + "layout"

    output_text=""
    # Render some components in $pango_inactive if $monitor is not the active monitor
    if [[ "${selmon}" = 0 ]]; then
	    local pango_tag_default="${pango_inactive}"
	    local pango_layout="${pango_inactive}"
    fi

    for component in "${full_components_list[@]}"; do
        case "${component}" in
            # If you use fewer than 9 tags, reduce this array accordingly
            [012345678])
            mask=$((1<<component))
            tag_text=${labels[component]}
            # Wrap component in the applicable nestable pango spans
            if (( "${activetags}" & mask )) 2>/dev/null; then tag_text="${pango_tag_active}${tag_text}</span>"; fi
            if (( "${urgenttags}" & mask )) 2>/dev/null; then tag_text="${pango_tag_urgent}${tag_text}</span>"; fi
            if (( "${selectedtags}" & mask )) 2>/dev/null; then tag_text="${pango_tag_selected}${tag_text}</span>"
            else
                tag_text="${pango_tag_default}${tag_text}</span>"
            fi
            output_text+="${tag_text}  "
            ;;
            layout)
                output_text+="${pango_layout}${layout} </span>"
            ;;
            *)
            output_text+="?" # If a "?" is visible on this module, something happened that shouldn't have happened
            ;;
        esac
    done
}

while [[ -n "$(pgrep waybar)" ]] ; do
    [[ ! -f "${dwl_output_filename}" ]] && printf -- '%s\n' \
				    "You need to redirect dwl stdout to ~/.cache/dwltags" >&2

    # Get info from the file
    dwl_latest_output_by_monitor="$(grep  "${monitor}" "${dwl_output_filename}" | tail -n${dwl_log_lines_per_focus_change})"
    layout="$(echo  "${dwl_latest_output_by_monitor}" | grep '^[[:graph:]]* layout' | cut -d ' ' -f 3- )"
    selmon="$(echo  "${dwl_latest_output_by_monitor}" | grep 'selmon' | cut -d ' ' -f 3)"

    # Get the tag bit mask as a decimal
    activetags="$(echo "${dwl_latest_output_by_monitor}" | grep '^[[:graph:]]* tags' | awk '{print $3}')"
    selectedtags="$(echo "${dwl_latest_output_by_monitor}" | grep '^[[:graph:]]* tags' | awk '{print $4}')"
    urgenttags="$(echo "${dwl_latest_output_by_monitor}" | grep '^[[:graph:]]* tags' | awk '{print $6}')"

    _cycle
    printf -- '{"text":" %s"}\n' "${output_text}"

    # 60-second timeout keeps this from becoming a zombified process when waybar is no longer running
    inotifywait -t 60 -qq --event modify "${dwl_output_filename}"
done
