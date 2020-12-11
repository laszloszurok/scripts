#!/bin/bash
[ -z $1 ] && echo "Usage: ./spiceup.sh path/to/an/image" && exit 1
! [ -f $1 ] && echo "The given argument is not a valid file" && exit 1

# running wal
wal -i $1

~/scripts/misc/genzathurarc

if [ -d "/opt/spotify" ]; then
    # gaining read and write permissions over spotify files
    sudo chmod a+wr /opt/spotify
    sudo chmod a+wr /opt/spotify/Apps -R
else
    echo "Please run Spotify to generate it's directory structure, then run this script again"
    exit 1
fi

# generating config file
spicetify

# enabling spotify dev-tools
spicetify backup apply enable-devtool

# applying custom css theme for spotify
spicetify update

# basic settings
spicetify config spotify_path /opt/spotify
spicetify config prefs_path "$HOME/.config/spotify/prefs"
spicetify config current_theme Spicy

# installing lyrics fetching app for spotify
cd "$(dirname "$(spicetify -c)")/CustomApps"
git clone https://github.com/khanhas/genius-spicetify
mv "genius-spicetify" lyrics
spicetify config custom_apps lyrics
spicetify apply
