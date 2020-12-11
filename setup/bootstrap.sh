#!/bin/bash

stty_orig=$(stty -g)                     # save original terminal setting.
stty -echo                               # turn-off echoing.
IFS= read -p "sudo password:" -r passwd  # read the password
stty "$stty_orig"                        # restore terminal setting.

# checking who is the current user
current_user=$(whoami)

# check internet connection
systemctl enable --now NetworkManager
ping -q -w 1 -c 1 `ip r | grep default | cut -d ' ' -f 3` > /dev/null && echo "internet connection ok" || `echo "no internet connection"; exit 1`

# sync mirrors, update the system
pacman -Syyu

# fixing wireless driver, connecting to wifi
echo $passwd | sudo -S pacman -S --noconfirm dkms git
git clone https://github.com/lwfinger/rtw88.git $HOME/.config/rtw88
cd $HOME/.config/rtw88
echo $passwd | sudo -S make
make install
cd
echo $passwd | sudo -S dkms add ./.config/rtw88
echo $passwd | sudo -S dkms install rtlwifi-new/0.6
nmtui

# x related
echo $passwd | sudo -S pacman -S --noconfirm \
    pacman -S xf86-video-intel xf86-video-amdgpu xorg xorg-xinit

# installing my most used software

# graphical file explorer
echo $passwd | sudo -S pacman -S --noconfirm \
    pacman -S pcmanfm-gtk3 gvfs gvfs-mtp ntfs-3g

# archiving tools
echo $passwd | sudo -S pacman -S --noconfirm \
    pacman -S zip unzip xarchiver

# pdf reader and office suite
echo $passwd | sudo -S pacman -S --noconfirm \
    pacman -S zathura zathura-pdf-poppler libreoffice-still

# themeing tools and themes
echo $passwd | sudo -S pacman -S --noconfirm \
    pacman -S lxappearance qt5ct arc-gtk-theme arc-icon-theme picom python-pywal

# shell
echo $passwd | sudo -S pacman -S --noconfirm \
    pacman -S zsh zsh-syntax-highlighting

# other x tools
echo $passwd | sudo -S pacman -S --noconfirm \
    pacman -S numlockx xclip xautolock xwallpaper

# virt-manager
echo $passwd | sudo -S pacman -S --noconfirm \
    pacman -S virt-manager qemu ebtables dnsmasq
usermod -aG libvirt $current_user
systemctl enable --now libvirtd
virsh net-autostart default

# fonts
echo $passwd | sudo -S pacman -S --noconfirm \
    pacman -S ttf-font-awesome ttf-dejavu

# browsers
echo $passwd | sudo -S pacman -S --noconfirm \
    pacman -S firefox qutebrowser

# multimedia
echo $passwd | sudo -S pacman -S --noconfirm \
    pacman -S mpv pulseaudio pulseaudio-alsa playerctl ffmpeg

# vifm
echo $passwd | sudo -S pacman -S --noconfirm \
    pacman -S vifm ffmpegthumbnailer ueberzug

# printing service
echo $passwd | sudo -S pacman -S --noconfirm pacman -S cups
systemctl enable org.cups.cupsd.socket

# firewall
echo $passwd | sudo -S pacman -S --noconfirm pacman -S ufw
ufw default deny incoming
ufw default allow outgoing
ufw enable

# power saving
echo $passwd | sudo -S pacman -S --noconfirm pacman -S powertop
sh -c "echo -e '[Unit]\nDescription=PowerTop\n\n[Service]\nType=oneshot\nRemainAfterExit=true\nExecStart=/usr/bin/powertop --auto-tune\n\n[Install]\nWantedBy=multi-user.target\n' > /etc/systemd/system/powertop.service"
systemctl enable --now powertop

# neovim
echo $passwd | sudo -S pacman -S --noconfirm \
    pacman -S nodejs npm python-pip neovim
sudo -u $current_user python3 -m pip install --user --upgrade pynvim

# misc
echo $passwd | sudo -S pacman -S --noconfirm \
    pacman -S qbittorrent gimp scrot lxsession dunst sxiv texlive-most usbutils newsboat youtube-dl pass translate-shell galculator gnu-netcat caclurse

# installing yay
git clone https://aur.archlinux.org/yay.git $HOME/source
cd $HOME/source/yay
echo $passwd | sudo -S makepkg -si

cd

# installing softwer from the AUR
echo $passwd | sudo -S yay -Sy spotify
echo $passwd | sudo -S yay -Sy spicetify-cli
echo $passwd | sudo -S yay -Sy protonvpn-cli-ng
echo $passwd | sudo -S yay -Sy windscribe-cli
echo $passwd | sudo -S yay -Sy hugo
echo $passwd | sudo -S yay -Sy vscodium-bin
echo $passwd | sudo -S yay -Sy ripcord
echo $passwd | sudo -S yay -Sy brave-bin
echo $passwd | sudo -S yay -Sy scrcpy
echo $passwd | sudo -S yay -Sy palenight-gtk-theme
echo $passwd | sudo -S yay -Sy nextdns
echo $passwd | sudo -S yay -Sy zoxide-bin

# nextdns settings
echo $passwd | sudo -S nextdns install -config 51a3bd -report-client-info -auto-activate

# service to launch slock on suspend
echo $passwd | sudo -S echo "[Unit]
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
WantedBy=suspend.target" > /etc/systemd/system/slock@.service

echo $passwd | sudo -S systemctl enable slock@$current_user.service

# disable tty swithcing when X is running, so the lockscreen cannot be bypassed
echo $passwd | sudo -S echo "Section \"ServerFlags\"
    Option \"DontVTSwitch\" \"True\"
EndSection" > /etc/X11/xorg.conf.d/xorg.conf

# cloning my configs from github to a bare repository for config file management
echo ".cfg" >> .gitignore
git clone --bare https://github.com/laszloszurok/suckless-arch $HOME/.cfg
alias cfg="/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME"
cfg config --local status.showUntrackedFiles no
cfg checkout -f

# cloning my suckless builds
git clone https://github.com/laszloszurok/dwm.git $HOME/source/suckless-builds/dwm
git clone https://github.com/laszloszurok/dwmblocks.git $HOME/source/suckless-builds/dwmblocks
git clone https://github.com/laszloszurok/dmenu.git $HOME/source/suckless-builds/dmenu
git clone https://github.com/laszloszurok/st.git $HOME/source/suckless-builds/st
git clone https://github.com/laszloszurok/slock.git $HOME/source/suckless-builds/slock
git clone https://github.com/laszloszurok/wmname.git $HOME/source/suckless-builds/wmname

# installing my suckless builds
cd $HOME/source/suckless-builds/dwm
echo $passwd | sudo -S -u $current_user make install
cd ../dwmblocks
echo $passwd | sudo -S -u $current_user make install
cd ../dmenu
echo $passwd | sudo -S -u $current_user make install
cd ../st
echo $passwd | sudo -S -u $current_user make install
cd ../slock
echo $passwd | sudo -S -u $current_user make install
cd ../wmname
echo $passwd | sudo -S -u $current_user make install

cd

# cloning my wallpaper repo
git clone https://github.com/laszloszurok/Wallpapers $HOME/pictures/wallpapers

# spotify wm
git clone https://github.com/dasJ/spotifywm.git $HOME/.config/spotifywm
cd $HOME/.config/spotifywm
make
echo $passwd | sudo -S -u $current_user echo "LD_PRELOAD=/usr/lib/libcurl.so.4:$HOME/.config/spotifywm/spotifywm.so /usr/bin/spotify" > /usr/local/bin/spotify
echo $passwd | sudo -S chmod +x /usr/local/spotify

cd /home/$current_user

# changing the default shell to zsh
mkdir $HOME/.cache/zsh
echo $passwd | sudo -S echo "ZDOTDIR=\$HOME/.config/zsh" > /etc/zsh/zshenv
echo $passwd | sudo -S -u $current_user chsh -s /usr/bin/zsh

echo $passwd | sudo -S mkdir /usr/share/xsessions
echo $passwd | sudo -S echo "[Desktop Entry]
Encoding=UTF-8
Name=dwm
Comment=Dynamic Window Manager
Exec=/usr/local/bin/dwm
Type=Application" > /usr/share/xsessions/dwm.desktop

# touchpad settings
echo $passwd | sudo -S echo "Section \"InputClass\"
    Identifier \"touchpad\"
    Driver \"libinput\"
    MatchIsTouchpad \"on\"
    Option \"Tapping\" \"on\"
    Option \"NaturalScrolling\" \"true\"
EndSection" > /etc/X11/xorg.conf.d/30-touchpad.conf

# theme settings
echo $passwd | sudo -S echo "QT_QPA_PLATFORMTHEME=qt5ct" >> /etc/environment

echo "
Finished
Please reboot your computer"
