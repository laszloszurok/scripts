#!/bin/bash

packagelist="https://raw.githubusercontent.com/laszloszurok/scripts/master/setup/packagelist.csv"

src_dir="$HOME/source"

stty_orig=$(stty -g)                     # save original terminal setting.
stty -echo                               # turn-off echoing.
IFS= read -p "sudo password:" -r passwd  # read the password
stty "$stty_orig"                        # restore terminal setting.

exec_cmd() {
    printf "%s\n" "$passwd" | $1
}

sysctl_enable() {
    exec_cmd "sudo -S systemctl enable $1"
}

write_to_file() {
    printf "%s\n" "Writing $1"
    if [ "$3" == "-a" ]; then
        printf '%s' "$passwd" | sudo -S tee -a "$1" <<< "$2" > /dev/null 2>&1
    else
        printf '%s' "$passwd" | sudo -S tee "$1" <<< "$2" > /dev/null 2>&1
    fi
    printf "Done\n"
}

git_cln() {
    progname="$(basename "$1" .git)"
    if [ -n "$3" ]; then
        git clone "$1" "$2/$3/$progname"
    else
        git clone "$1" "$2/$progname"
    fi
}

install_aur_helper() {
    git_cln "https://aur.archlinux.org/paru.git" "$src_dir"
    cd "$src_dir/$progname" || return 1
    makepkg -si
}

install_packages() {
	([ -f "$packagelist" ] && cp "$packagelist" /tmp/packagelist.csv) || curl -Ls "$packagelist" | sed '/^#/d' > /tmp/packagelist.csv
    total=$(wc -l < /tmp/packagelist.csv)
	while IFS=, read -r tag package _ ; do
        n=$((n+1))
        printf "%s\n" "Installing $package ($n/$total)"
		case "$tag" in
			"A") paru -S "$package" --sudoloop --noconfirm > /dev/null 2>&1 ;;
			*) exec_cmd "sudo -S pacman -S --noconfirm $package" > /dev/null 2>&1 ;;
		esac
	done < /tmp/packagelist.csv
}

install_from_src() {
    cd "$1" || return 1
    exec_cmd "sudo -S make install"
    cd
}

install_dotfiles() {
    git clone --bare https://github.com/laszloszurok/config "$HOME"/.cfg
    git --git-dir="$HOME"/.cfg/ --work-tree="$HOME" checkout -f
    git --git-dir="$HOME"/.cfg/ --work-tree="$HOME" config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
    git --git-dir="$HOME"/.cfg/ --work-tree="$HOME" fetch
    git --git-dir="$HOME"/.cfg/ --work-tree="$HOME" branch -u origin/master master
}

# checking who is the current user
current_user=$(whoami)

# enable colored output for pacman
exec_cmd "sudo -S sed -i '/Color/s/^#//g' /etc/pacman.conf"

# install git
exec_cmd "sudo -S pacman -S --noconfirm git"

# installing an aur helper
install_aur_helper

# install every package from packagelist
install_packages

# installing pynvim
exec_cmd "sudo -S -u $current_user python3 -m pip install --user --upgrade pynvim"

# nextdns settings
exec_cmd "sudo -S nextdns install -config 51a3bd -report-client-info -auto-activate"

# virt-manager
exec_cmd "sudo -S usermod -aG libvirt $current_user"
sysctl_enable libvirtd
exec_cmd "sudo -S virsh net-autostart default"

# printing service
sysctl_enable org.cups.cupsd.socket

# firewall
exec_cmd "sudo -S ufw default deny incoming"
exec_cmd "sudo -S ufw default allow outgoing"
sysctl_enable ufw
exec_cmd "sudo -S ufw enable"

# power saving service
sysctl_enable auto-cpufreq

# cloning my configs from github to a bare repository for config file management
install_dotfiles

# cloning my scripts
git_cln "https://github.com/laszloszurok/scripts.git" "$src_dir"

# cloning my suckless builds
git_cln "https://github.com/laszloszurok/dwm.git"       "$src_dir"
git_cln "https://github.com/laszloszurok/dwmblocks.git" "$src_dir"
git_cln "https://github.com/laszloszurok/dmenu.git"     "$src_dir"
git_cln "https://github.com/laszloszurok/st.git"        "$src_dir"
git_cln "https://github.com/laszloszurok/slock.git"     "$src_dir"
git_cln "https://github.com/laszloszurok/wmname.git"    "$src_dir"

# installing my suckless builds
install_from_src "$src_dir/dwm"
install_from_src "$src_dir/dwmblocks"
install_from_src "$src_dir/dmenu"
install_from_src "$src_dir/st"
install_from_src "$src_dir/slock"
install_from_src "$src_dir/wmname"

# changing the default shell to zsh
write_to_file "/etc/zsh/zshenv" "ZDOTDIR=\$HOME/.config/zsh"
exec_cmd "sudo -S chsh -s /usr/bin/zsh $current_user"

exec_cmd "sudo -S mkdir /usr/share/xsessions"
write_to_file "/usr/share/xsessions/dwm.desktop" "[Desktop Entry]
Encoding=UTF-8
Name=dwm
Comment=Dynamic Window Manager
Exec=/usr/local/bin/dwm
Type=Application"

# touchpad settings
write_to_file "/etc/X11/xorg.conf.d/30-touchpad.conf" "Section \"InputClass\"
    Identifier \"touchpad\"
    Driver \"libinput\"
    MatchIsTouchpad \"on\"
    Option \"Tapping\" \"on\"
    Option \"NaturalScrolling\" \"true\"
EndSection"

# automatically spin down the secondary hdd in my machine if it is not in use
write_to_file "/usr/lib/systemd/system-sleep/hdparm" "#!/bin/sh

case \$1 in post)
        /usr/bin/hdparm -q -S 60 -y /dev/sda
        ;;
esac"

exec_cmd "sudo -S chmod +x /usr/lib/systemd/system-sleep/hdparm"

write_to_file "/etc/systemd/system/hdparm.service" "[Unit]
Description=hdparm sleep

[Service]
Type=oneshot
ExecStart=/usr/bin/hdparm -q -S 60 -y /dev/sda

[Install]
WantedBy=multi-user.target"

sysctl_enable "hdparm.service"
################################################################################

# disable hardware bell on boot
write_to_file "/etc/modprobe.d/pcspkr-blacklist.conf" "blacklist pcspkr"

# service to turn off the display and suspend the system after some time of inactivity on the tty (X server is not running)
write_to_file "/etc/systemd/system/inactivity_tty.service" "[Unit]
Description=suspend os after inactivity on the tty

[Service]
Type=simple
ExecStart=$HOME/source/scripts/utils/inactivity_tty
Restart=on-failure
RestartSec=30

[Install]
WantedBy=multi-user.target"

sysctl_enable "inactivity_tty.service"

# service to launch slock on suspend (X server is running)
write_to_file "/etc/systemd/system/slock@.service" "[Unit]
Description=Lock X session using slock for user %i
Before=sleep.target
Before=suspend.target

[Service]
User=%i
Type=simple
Environment=DISPLAY=:0
ExecStartPre=/usr/bin/xset dpms force suspend
ExecStart=/usr/local/bin/slock
TimeoutSec=infinity

[Install]
WantedBy=sleep.target
WantedBy=suspend.target"

sysctl_enable "slock@$current_user.service"

# disable tty swithcing when X is running, so the lockscreen cannot be bypassed
write_to_file "/etc/X11/xorg.conf.d/xorg.conf" "Section \"ServerFlags\"
    Option \"DontVTSwitch\" \"True\"
EndSection"

# cron service
sysctl_enable "cronie.service"
crontab "$HOME"/.config/cronjobs

# udev rule to allow users in the "video" group to set the display brightness
write_to_file "/etc/udev/rules.d/90-backlight.rules" "SUBSYSTEM==\"backlight\", ACTION==\"add\", \
  RUN+=\"/bin/chgrp video /sys/class/backlight/%k/brightness\", \
  RUN+=\"/bin/chmod g+w /sys/class/backlight/%k/brightness\""

# cloning my wallpapers
git_cln "https://github.com/laszloszurok/Wallpapers.git" "$HOME/pictures/"

# installing gtk palenight theme
git_cln "https://github.com/jaxwilko/gtk-theme-framework.git" "$src_dir"
cd "$src_dir/gtk-theme-framework" || exit
exec_cmd "sudo ./main.sh -i -o"

# global gtk-2 settings
write_to_file "/etc/gtk-2.0/gtkrc" "gtk-theme-name=\"palenight\"
gtk-icon-theme-name=\"palenight\"
gtk-font-name=\"Sans 9\"
gtk-cursor-theme-name=\"palenight\"
gtk-cursor-theme-size=0
gtk-toolbar-style=GTK_TOOLBAR_ICONS
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=1
gtk-menu-images=1
gtk-enable-event-sounds=1
gtk-enable-input-feedback-sounds=1
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=\"hintfull\""

# global gtk-3 settings
write_to_file "/etc/gtk-3.0/settings.ini" "[Settings]
gtk-theme-name=palenight
gtk-icon-theme-name=palenight
gtk-font-name=Sans 9
gtk-cursor-theme-name=palenight
gtk-cursor-theme-size=0
gtk-toolbar-style=GTK_TOOLBAR_ICONS
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=1
gtk-menu-images=1
gtk-enable-event-sounds=1
gtk-enable-input-feedback-sounds=1
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintfull
gtk-application-prefer-dark-theme=true"

# unify gtk and qt themes
write_to_file "/etc/environment" "QT_QPA_PLATFORMTHEME=gtk2" "-a"

printf "\nFinished\nPlease reboot your computer\n"
