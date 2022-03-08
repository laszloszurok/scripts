#!/bin/sh

# download media in m3u8 format and convert it to mkv using ffmpeg
#
# provide the url/path to the m3u8 file as the first argument
#
# to find the m3u8 file on a website: 
# 1. open dev tools 
# 2. go to Network tab 
# 3. filter to m3u8 
# 4. click on the result
# 5. copy Request URL from Headers

ffmpeg -i "$1" -c copy output.mkv
