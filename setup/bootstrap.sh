#!/bin/bash

stty_orig=$(stty -g)                     # save original terminal setting.
stty -echo                               # turn-off echoing.
IFS= read -p "sudo password:" -r passwd  # read the password
stty "$stty_orig"                        # restore terminal setting.

# checking who is the current user
current_user=$(whoami)

# sync mirrors, update the system
echo $passwd | sudo -S pacman -Syyu

# x related
echo $passwd | sudo -S pacman -S --noconfirm \
    xf86-video-intel xf86-video-amdgpu xorg xorg-xinit

# installing my most used software

# git
echo $passwd | sudo -S pacman -S --noconfirm git

# graphical file explorer
echo $passwd | sudo -S pacman -S --noconfirm \
    pcmanfm-gtk3 gvfs gvfs-mtp ntfs-3g

# archiving tools
echo $passwd | sudo -S pacman -S --noconfirm \
    zip unzip xarchiver

# pdf reader and office suite
echo $passwd | sudo -S pacman -S --noconfirm \
    zathura zathura-pdf-poppler libreoffice-still

# themeing tools and themes
echo $passwd | sudo -S pacman -S --noconfirm \
    lxappearance qt5ct arc-gtk-theme arc-icon-theme picom python-pywal

# shell
echo $passwd | sudo -S pacman -S --noconfirm \
    zsh zsh-syntax-highlighting

# other x tools
echo $passwd | sudo -S pacman -S --noconfirm \
    numlockx xclip xautolock xwallpaper

# virt-manager
echo $passwd | sudo -S pacman -S --noconfirm \
    virt-manager qemu ebtables dnsmasq
echo $passwd | sudo -S usermod -aG libvirt $current_user
echo $passwd | sudo -S systemctl enable --now libvirtd
echo $passwd | sudo -S virsh net-autostart default

# fonts
echo $passwd | sudo -S pacman -S --noconfirm \
    ttf-font-awesome ttf-dejavu

# browsers
echo $passwd | sudo -S pacman -S --noconfirm \
    firefox qutebrowser

# multimedia
echo $passwd | sudo -S pacman -S --noconfirm \
    mpv pulseaudio pulseaudio-alsa playerctl ffmpeg

# vifm
echo $passwd | sudo -S pacman -S --noconfirm \
    vifm ffmpegthumbnailer ueberzug

# printing service
echo $passwd | sudo -S pacman -S --noconfirm cups
echo $passwd | sudo -S systemctl enable org.cups.cupsd.socket

# firewall
echo $passwd | sudo -S pacman -S --noconfirm ufw
ufw default deny incoming
ufw default allow outgoing
echo $passwd | sudo -S ufw enable

# power saving
echo $passwd | sudo -S pacman -S --noconfirm powertop
sh -c "echo -e '[Unit]\nDescription=PowerTop\n\n[Service]\nType=oneshot\nRemainAfterExit=true\nExecStart=/usr/bin/powertop --auto-tune\n\n[Install]\nWantedBy=multi-user.target\n' > /etc/systemd/system/powertop.service"
echo $passwd | sudo -S systemctl enable --now powertop

# neovim
echo $passwd | sudo -S pacman -S --noconfirm \
    nodejs npm python-pip neovim
echo $passwd | sudo -S -u $current_user python3 -m pip install --user --upgrade pynvim

# misc
echo $passwd | sudo -S pacman -S --noconfirm \
    qbittorrent gimp scrot lxsession dunst sxiv texlive-most usbutils newsboat youtube-dl pass translate-shell galculator gnu-netcat caclurse

# installing yay
git clone https://aur.archlinux.org/yay.git $HOME/source/yay
cd $HOME/source/yay
makepkg -si

cd

# installing softwer from the AUR
yay -S --noconfirm spotify
yay -S --noconfirm spicetify-cli
yay -S --noconfirm protonvpn-cli-ng
yay -S --noconfirm windscribe-cli
yay -S --noconfirm hugo
yay -S --noconfirm vscodium-bin
yay -S --noconfirm ripcord
yay -S --noconfirm brave-bin
yay -S --noconfirm scrcpy
yay -S --noconfirm palenight-gtk-theme
yay -S --noconfirm nextdns
yay -S --noconfirm zoxide-bin

# nextdns settings
echo $passwd | sudo -S nextdns install -config 51a3bd -report-client-info -auto-activate

# disable tty swithcing when X is running, so the lockscreen cannot be bypassed
echo $passwd | sudo -S tee /etc/X11/xorg.conf.d/xorg.conf <<< "Section \"ServerFlags\"
    Option \"DontVTSwitch\" \"True\"
EndSection"

# cloning my configs from github to a bare repository for config file management
echo ".cfg" >> .gitignore
git clone --bare https://github.com/laszloszurok/suckless-arch $HOME/.cfg
alias cfg="/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME"
cfg config --local status.showUntrackedFiles no
cfg checkout -f

# cloning my scripts
git clone https://github.com/laszloszurok/scripts $HOME/source/scripts

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

# cloning my wallpapers
git clone https://github.com/laszloszurok/Wallpapers $HOME/pictures/wallpapers

# spotify wm
git clone https://github.com/dasJ/spotifywm.git $HOME/.config/spotifywm
cd $HOME/.config/spotifywm
make
echo $passwd | sudo -S -u $current_user tee /usr/local/bin/spotify <<< "LD_PRELOAD=/usr/lib/libcurl.so.4:$HOME/.config/spotifywm/spotifywm.so /usr/bin/spotify"
echo $passwd | sudo -S chmod +x /usr/local/spotify

cd

# changing the default shell to zsh
mkdir $HOME/.cache/zsh
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

# theme settings
echo $passwd | sudo -S tee -a /etc/environment <<< "QT_QPA_PLATFORMTHEME=qt5ct"

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

echo "
Finished
Please reboot your computer"
