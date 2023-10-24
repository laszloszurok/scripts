#!/bin/bash

if ffprobe "$1" -show_streams | grep ^codec_name=h264 ; then
    printf "Video encoded with h264.\n"
    read -rs -n1 -p "Do you want to reencode with h265? (y/n) " key
    case $key in
        "y") 
            ffmpeg -i "$1" -vcodec libx265 -crf 28 output.mp4 ;;
        *) 
            exit 0 ;;
    esac
fi
