#!/bin/bash

[ ! -f ./packagelist ] && echo "Missing packagelist! Aborting..." && exit 1

stty_orig=$(stty -g)                     # save original terminal setting.
stty -echo                               # turn-off echoing.
IFS= read -p "sudo password:" -r passwd  # read the password
stty "$stty_orig"                        # restore terminal setting.

# checking who is the current user
current_user=$(whoami)

# enable colored output for pacman
echo $passwd | sudo -S sed -i '/Color/s/^#//g' /etc/pacman.conf

# sync mirrors, update the system
echo $passwd | sudo -S pacman -Syyu

# install git
echo $passwd | sudo -S pacman -S --noconfirm git

# installing paru
git clone https://aur.archlinux.org/paru.git $HOME/source/paru
cd $HOME/source/paru
makepkg -si
cd

# install every package from packagelist
cat ./packagelist | xargs paru --sudoloop -S --noconfirm

# installing pynvim
echo $passwd | sudo -S -u $current_user python3 -m pip install --user --upgrade pynvim

# nextdns settings
echo $passwd | sudo -S nextdns install -config 51a3bd -report-client-info -auto-activate

# virt-manager
echo $passwd | sudo -S usermod -aG libvirt $current_user
echo $passwd | sudo -S systemctl enable libvirtd
echo $passwd | sudo -S virsh net-autostart default

# printing service
echo $passwd | sudo -S systemctl enable org.cups.cupsd.socket

# firewall
echo $passwd | sudo -S ufw default deny incoming
echo $passwd | sudo -S ufw default allow outgoing
echo $passwd | sudo -S systemctl enable ufw
echo $passwd | sudo -S ufw enable

# windscribe vpn service
echo $passwd | sudo -S systemctl enable windscribe

# power saving service
echo $passwd | sudo -S systemctl enable tlp

# automatically spin down the secondary hdd in my machine if it is not in use
echo $passwd | sudo -S tee /usr/lib/systemd/system-sleep/hdparm <<< "#!/bin/sh

case \$1 in post)
        /usr/bin/hdparm -q -S 60 -y /dev/sda
        ;;
esac"

echo $passwd | sudo -S tee /etc/systemd/system/hdparm.service <<< "[Unit]
Description=hdparm sleep

[Service]
Type=oneshot
ExecStart=/usr/bin/hdparm -q -S 60 -y /dev/sda

[Install]
WantedBy=multi-user.target"
################################################################################

# disable tty swithcing when X is running, so the lockscreen cannot be bypassed
echo $passwd | sudo -S tee /etc/X11/xorg.conf.d/xorg.conf <<< "Section \"ServerFlags\"
    Option \"DontVTSwitch\" \"True\"
EndSection"

# cloning my configs from github to a bare repository for config file management
git clone --bare https://github.com/laszloszurok/config $HOME/.cfg
/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME config --local status.showUntrackedFiles no
/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME checkout -f

# cloning my scripts
git clone https://github.com/laszloszurok/scripts $HOME/source/scripts

# cloning my suckless builds
suckless_dir="$HOME/source/suckless-builds"
git clone https://github.com/laszloszurok/dwm.git $suckless_dir/dwm
git clone https://github.com/laszloszurok/dwmblocks.git $suckless_dir/dwmblocks
git clone https://github.com/laszloszurok/dmenu.git $suckless_dir/dmenu
git clone https://github.com/laszloszurok/st.git $suckless_dir/st
git clone https://github.com/laszloszurok/slock.git $suckless_dir/slock
git clone https://github.com/laszloszurok/wmname.git $suckless_dir/wmname

# installing my suckless builds
cd $suckless_dir
for d in $suckless_dir/*/ ; do
    cd "$d"
    echo $passwd | sudo -S make install
    cd ..
done
cd

# cloning my wallpapers
git clone https://github.com/laszloszurok/Wallpapers $HOME/pictures/wallpapers

# installing gtk palenight theme
git clone https://github.com/jaxwilko/gtk-theme-framework.git $HOME/source/palenight-gtk
cd $HOME/source/palenight-gtk
./main.sh -i -o

# global gtk-2 settings
echo $passwd | sudo -S tee /etc/gtk-2.0/gtkrc <<< "gtk-theme-name=\"palenight\"
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
echo $passwd | sudo -S tee /etc/gtk-3.0/settings.ini <<< "[Settings]
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
echo $passwd | sudo -S tee -a /etc/environment <<< "QT_QPA_PLATFORMTHEME=gtk2"

# spotify wm
git clone https://github.com/dasJ/spotifywm.git $HOME/.config/spotifywm
cd $HOME/.config/spotifywm
make
echo $passwd | sudo -S -u $current_user tee /usr/local/bin/spotify <<< "LD_PRELOAD=/usr/lib/libcurl.so.4:$HOME/.config/spotifywm/spotifywm.so /usr/bin/spotify"
echo $passwd | sudo -S chmod +x /usr/local/spotify

cd

# changing the default shell to zsh
echo $passwd | sudo -S tee /etc/zsh/zshenv <<< "ZDOTDIR=\$HOME/.config/zsh"
chsh -s /usr/bin/zsh

echo $passwd | sudo -S mkdir /usr/share/xsessions
echo $passwd | sudo -S tee /usr/share/xsessions/dwm.desktop <<< "[Desktop Entry]
Encoding=UTF-8
Name=dwm
Comment=Dynamic Window Manager
Exec=/usr/local/bin/dwm
Type=Application"

# touchpad settings
echo $passwd | sudo -S tee /etc/X11/xorg.conf.d/30-touchpad.conf <<< "Section \"InputClass\"
    Identifier \"touchpad\"
    Driver \"libinput\"
    MatchIsTouchpad \"on\"
    Option \"Tapping\" \"on\"
    Option \"NaturalScrolling\" \"true\"
EndSection"

# service to launch slock on suspend
echo $passwd | sudo -S tee /etc/systemd/system/slock@.service <<< "[Unit]
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

echo $passwd | sudo -S systemctl enable slock@$current_user.service

# cron service
echo $passwd | sudo -S systemctl enable cronie.service
crontab $HOME/.config/cronjobs

# udev rule to allow users in the "video" group to set the display brightness
echo $passwd | sudo -S tee /etc/udev/rules.d/90-backlight.rules <<< "SUBSYSTEM==\"backlight\", ACTION==\"add\", \
  RUN+=\"/bin/chgrp video /sys/class/backlight/%k/brightness\", \
  RUN+=\"/bin/chmod g+w /sys/class/backlight/%k/brightness\""

echo "
Finished
Please reboot your computer"
