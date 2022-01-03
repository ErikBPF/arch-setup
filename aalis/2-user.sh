#!/usr/bin/env bash

#Variable declarations
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

#Enable logging!
touch ${SCRIPT_DIR}/logs/user.log
exec &> >(tee ${SCRIPT_DIR}/logs/user.log)

echo -ne "\e[95m"
echo    "---------------------------------"
echo    "         Preflight Check         "
echo -n "---------------------------------"
echo -e "\e[39m"
if [ -f ${SCRIPT_DIR}/script_funcs ]; then source ${SCRIPT_DIR}/script_funcs; output ${LIGHT_GREEN} "FOUND ${SCRIPT_DIR}/script_funcs!"; else echo -e "\e[31mCannot find ${SCRIPT_DIR}/script_funcs, cannot continue\e[39m"; sleep 2; exit 1; fi
if [ -f ${SCRIPT_DIR}/sysconfig.conf ]; then source ${SCRIPT_DIR}/sysconfig.conf; output ${LIGHT_GREEN} "FOUND ${SCRIPT_DIR}/sysconfig.conf!"; else echo -e "\e[31mCannot find ${SCRIPT_DIR}/sysconfig.conf, cannot continue\e[39m"; sleep 2; exit 1; fi
output ${LIGHT_GREEN} "Preflight Check done! Moving on in 2 seconds"
sleep 2

banner ${LIGHT_PURPLE} "Enabling User Systemd services"
systemctl daemon-reload
systemctl --user enable ssh-agent
systemctl --user enable emacs

banner ${LIGHT_PURPLE} "Installing AUR Software"
output ${YELLOW} "Installing Yay"
cd ~
git clone https://aur.archlinux.org/yay-bin.git
cd yay-bin
makepkg -si --noconfirm
cd ~
rm yay-bin -rf


if [[ "$is_laptop" == "yes" ]]; then
    output ${YELLOW} "Installing Laptop specific tools"
    yay -S --noconfirm --needed tlpui
fi

if [[ "$use_swap" == "yes"  ]]; then
    output ${YELLOW} "Installing ZRAM modules"
    yay -S --noconfirm --needed zramd
    sudo systemctl enable zramd.service
fi

#DE Specific Install
if [[ "$desktopenv" == "xfce"  ]]; then
    output ${YELLOW} "Installing XFCE specific AUR packages"
    yay -S --noconfirm --needed gnome-ssh-askpass3 menulibre mugshot xfce4-docklike-plugin-ng-git xfce4-windowck-plugin
    output ${YELLOW} "Setting SSH_ASKPASS variable to gnome-ssh-askpass3 for gui ssh prompts"
    echo "SSH_ASKPASS=/usr/bin/gnome-ssh-askpass3" >> /etc/environment
elif [[ "$desktopenv" == "gnome"  ]]; then
    output ${YELLOW} "Installing Gnome specific AUR packages"
    yay -S --noconfirm --needed gnome-ssh-askpass3 menulibre mugshot
    output ${YELLOW} "Setting SSH_ASKPASS variable to gnome-ssh-askpass3 for gui ssh prompts"
    echo "SSH_ASKPASS=/usr/bin/gnome-ssh-askpass3" >> /etc/environment
elif [[ "$desktopenv" == "kde"  ]]; then
    output ${YELLOW} "Installing KDE specific packages"
    yay -S --noconfirm --needed ant-dracula-kde-theme-git ant-dracula-kvantum-theme-git kde-servicemenus-pdf rootactions-servicemenu plasma5-applets-window-appmenu-git plasma5-applets-window-buttons-git plasma5-applets-window-title-git
    output ${YELLOW} "Setting SSH_ASKPASS variable to ksshaskpass for gui ssh prompts"
    echo "SSH_ASKPASS=/usr/bin/ksshaskpass" >> /etc/environment
elif [[ "$desktopenv" == "cinnamon"  ]]; then
    output ${YELLOW} "Installing Cinnamon specific packages"
    yay -S --noconfirm --needed gnome-ssh-askpass3 menulibre mugshot
    output ${YELLOW} "Setting SSH_ASKPASS variable to gnome-ssh-askpass3 for gui ssh prompts"
    echo "SSH_ASKPASS=/usr/bin/gnome-ssh-askpass3" >> /etc/environment
elif [[ "$desktopenv" == "qtile"  ]]; then
    output ${YELLOW} "Installing Qtile specific packages"
    yay -S --noconfirm --needed gnome-ssh-askpass3 menulibre mugshot
    output ${YELLOW} "Setting SSH_ASKPASS variable to gnome-ssh-askpass3 for gui ssh prompts"
    echo "SSH_ASKPASS=/usr/bin/gnome-ssh-askpass3" >> /etc/environment
fi

output ${YELLOW} "Making yay ask to edit pkgbuild files and not ask for diff menu"
yay --editmenu --nodiffmenu --save

banner ${LIGHT_PURPLE} "SYSTEM READY FOR 3-post-install"
sleep 3
clear
