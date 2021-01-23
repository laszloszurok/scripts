#!/bin/bash

[ ! -f ./packagelist ] && "Missing packagelist! Aborting..." && exit 1

stty_orig=$(stty -g)                     # save original terminal setting.
stty -echo                               # turn-off echoing.
IFS= read -p "sudo password:" -r passwd  # read the password
stty "$stty_orig"                        # restore terminal setting.

# checking who is the current user
current_user=$(whoami)

# sync mirrors, update the system
echo $passwd | sudo -S pacman -Syyu

# install git
echo $passwd | sudo -S pacman -S --noconfirm git

# installing yay
git clone https://aur.archlinux.org/yay.git $HOME/source/yay
cd $HOME/source/yay
makepkg -si
cd

# install every package from packagelist
< ./packagelist | xargs yay --save --sudoloop -S --noconfirm

# installing pynvim
echo $passwd | sudo -S -u $current_user python3 -m pip install --user --upgrade pynvim

# nextdns settings
echo $passwd | sudo -S nextdns install -config 51a3bd -report-client-info -auto-activate

# virt-manager
echo $passwd | sudo -S usermod -aG libvirt $current_user
echo $passwd | sudo -S systemctl enable --now libvirtd
echo $passwd | sudo -S virsh net-autostart default

# printing service
echo $passwd | sudo -S systemctl enable org.cups.cupsd.socket

# firewall
echo $passwd | sudo -S ufw default deny incoming
echo $passwd | sudo -S ufw default allow outgoing
echo $passwd | sudo -S ufw enable

# power saving service
echo $passwd | sudo -S sh -c "echo -e '[Unit]\nDescription=PowerTop\n\n[Service]\nType=oneshot\nRemainAfterExit=true\nExecStart=/usr/bin/powertop --auto-tune\n\n[Install]\nWantedBy=multi-user.target\n' > /etc/systemd/system/powertop.service"
echo $passwd | sudo -S systemctl enable --now powertop

# cron service
echo $passwd | sudo -S systemctl enable cronie.service

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

# theme settings
echo $passwd | sudo -S tee -a /etc/environment <<< "QT_QPA_PLATFORMTHEME=gtk2"

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
