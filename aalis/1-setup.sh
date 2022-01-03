#!/usr/bin/env bash

# Variable Declarations
users=()
is_touchscreen=""
use_graphics=""
use_bluetooth=""
microcode=""
desktopenv=""
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

#Enable logging!
touch ${SCRIPT_DIR}/logs/setup.log
exec &> >(tee ${SCRIPT_DIR}/logs/setup.log)

echo -ne "\e[95m"
echo    "---------------------------------"
echo    "         Preflight Check         "
echo -n "---------------------------------"
echo -e "\e[39m"
if [ -f ${SCRIPT_DIR}/script_funcs ]; then source ${SCRIPT_DIR}/script_funcs; output ${LIGHT_GREEN} "FOUND ${SCRIPT_DIR}/script_funcs!"; else echo -e "\e[31mCannot find ${SCRIPT_DIR}/script_funcs, cannot continue\e[39m"; sleep 2; exit 1; fi
if [ -f ${SCRIPT_DIR}/sysconfig.conf ]; then source ${SCRIPT_DIR}/sysconfig.conf; output ${LIGHT_GREEN} "FOUND ${SCRIPT_DIR}/sysconfig.conf!"; else echo -e "\e[31mCannot find ${SCRIPT_DIR}/sysconfig.conf, cannot continue\e[39m"; sleep 2; exit 1; fi
output ${LIGHT_GREEN} "Preflight Check done! Moving on in 2 seconds"
sleep 2

banner ${LIGHT_PURPLE} "Configuring Pacman"
sed -i 's/^#Color/Color/' /etc/pacman.conf
sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
sed -i 's/^#Para/Para/' /etc/pacman.conf
pacman -Syu

banner ${LIGHT_PURPLE} "Setup Language to US and set locale, and hostname"
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
timedatectl set-ntp true
timedatectl set-timezone America/Sao_Paulo
systemctl enable systemd-timesyncd
hwclock --systohc
localectl set-locale LANG="en_US.UTF-8" LC_TIME="en_US.UTF-8"
localectl set-keymap us-acentos # Set keymaps
pacman -S --needed --noconfirm hunspell-en_us
read -p 'Hostname: ' hostname
echo "$hostname" >> /etc/hostname
echo "127.0.0.1 localhost" >> /etc/hosts
echo "127.0.0.1 $hostname" >> /etc/hosts
echo "::1       localhost" >> /etc/hosts
#Configure sudoers
sed -i 's/^# %wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers

banner ${LIGHT_PURPLE} "Installing Base System Packages"
pacman -S --needed --noconfirm base base-devel linux linux-firmware reflector git neovim yadm gnupg networkmanager dhclient dialog wpa_supplicant wireless_tools netctl inetutils openssh openvpn fzf pacman
systemctl enable NetworkManager
systemctl enable sshd
systemctl enable reflector.timer

banner ${LIGHT_PURPLE} "Installing Filesystem Packages"
pacman -S --needed --noconfirm ntfs-3g nfs-utils e2fsprogs smartmontools btrfs-progs gvfs gvfs-smb unzip unrar p7zip unarchiver

banner ${LIGHT_PURPLE} "Configuring User Directories"
pacman -S --needed --noconfirm xdg-user-dirs xdg-utils
xdg-user-dirs-update
output ${YELLOW} "Configuring environment variables"
echo >> /etc/profile
echo 'export XDG_CONFIG_HOME="$HOME/.config"' >> /etc/profile
echo 'export XDG_CACHE_HOME="$HOME/.cache"' >> /etc/profile
echo 'export XDG_DATA_HOME="$HOME/.local/share"' >> /etc/profile
echo 'export XDG_STATE_HOME="$HOME/.local/state"' >> /etc/profile
echo 'export GOPATH="$XDG_DATA_HOME/go"' >> /etc/profile
echo 'export CARGO_HOME="$XDG_DATA_HOME/cargo"' >> /etc/profile
echo 'export LESSHISTFILE="$XDG_CONFIG_HOME/less/history"' >> /etc/profile
echo 'export LESSKEY="$XDG_CONFIG_HOME/less/keys"' >> /etc/profile
echo 'export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME/npm"' >> /etc/profile


mkdir -p /etc/skel/.config/systemd/user
cp ${SCRIPT_DIR}/ssh-agent.service /etc/skel/.config/systemd/user/ssh-agent.service
echo "SSH_AUTH_SOCK  DEFAULT=${XDG_RUNTIME_DIR}/ssh-agent.socket" >> /etc/security/pam_env.conf


banner ${LIGHT_PURPLE} "Adding and Configuring Users"
#Ask for root password
addRootPass

#Additional User Prompt
while [[ "yes" == $(askYesNo "Would you like to add any additional users?") ]]; do addUserPass; done



banner ${LIGHT_PURPLE} "Configuring Base System"
if [[ "yes" == $(askYesNo "Do you want to install a graphical environment?") ]]; then
    output ${LIGHT_BLUE} "Ok, I will take you to the graphics installer, but first we still have some things to configure."
    use_graphics="yes"
    sleep 2
fi

if [[ "$is_laptop" == "yes" ]]; then
    output ${YELLOW} "Installing TLP and other battery management tools"
    pacman -S --noconfirm --needed acpi acpi_call tlp
    systemctl enable tlp
fi

#Processor Microcode Installer
while true; do
    read -p "$(output ${YELLOW} "What brand is your processor? [I]ntel or [A]MD?: ")" processor
    case $processor in
    I | i)
        output ${YELLOW} "========= Installing Intel Microcode ========="
        microcode="intel"
        pacman -S --needed --noconfirm intel-ucode
        break;;
    A | a)
        output ${YELLOW} "========= Installing AMD Microcode ========="
        microcode="amd"
        pacman -S --needed --noconfirm amd-ucode
        break;;
    *) output ${LIGHT_RED} "Invalid input";;
    esac
done

## Graphics installer
if [[ "$use_graphics" = "yes" ]]; then
    banner ${LIGHT_PURPLE} "Installing Graphical Environment"
    sleep 1

    #Network Manager
    output ${YELLOW} "======= Installing GUI components for Network Manager ========"
    pacman -S --needed --noconfirm network-manager-applet networkmanager-openvpn openvpn

    #Bluetooth
    if [[ "yes" == $(askYesNo "Would you like to download and enable Bluetooth?") ]]; then
        output ${YELLOW} "========= Installing Bluetooth ========="
        use_bluetooth="yes"
        pacman -S --needed --noconfirm bluez bluez-utils
        sed -i "250s/.*/AutoEnable=true/" /etc/bluetooth/main.conf
        systemctl enable bluetooth
    fi

    #Laptop Touchscreen
    if [[ "$is_laptop" = "yes" && "yes" == $(askYesNo "Does your laptop have touchscreen capability?") ]]; then
        output ${YELLOW} "========= Installing Wacom settings ========="
        is_touchscreen="yes"
        pacman -S --noconfirm --needed libwacom xf86-input-wacom iio-sensor-proxy
    fi

    #Audio Selection
    while true; do
        read -p "$(output ${YELLOW} "What audio driver would you like to install? Pulse[A]udio or Pipe[W]ire?: ")" audio
        case $audio in
        A | a)
            output ${YELLOW} "========= Installing PulseAudio protocols ========="
            pacman -S --needed --noconfirm alsa-utils pulseaudio pulseaudio-alsa pipewire-alsa gst-libav gst-plugins-ugly gst-plugins-bad
            break;;
        W | w)
            output ${YELLOW} "========= Installing PipeWire protocols ========="
            pacman -S --needed --noconfirm alsa-utils pipewire pipewire-media-session pipewire-pulse pipewire-alsa gst-libav gst-plugins-ugly gst-plugins-bad
            break;;
        *) output ${LIGHT_RED} "Invaild Input";;
        esac
    done

    #HP Printer configuration
    if [[ "yes" == $(askYesNo "Would you like to install HP Printer Modules?") ]]; then
        output ${YELLOW} "========= Installing HP modules ========="
        pacman -S --needed --noconfirm cups cups-filters hplip
        systemctl enable cups
    fi

    #Installer based on instructions from: https://boseji.com/posts/manjaro-kvm-virtmanager/
    if [[ "yes" == $(askYesNo "Would you like to install Virt-Manager?") ]]; then
        output ${YELLOW} "========= Installing Virt-Manager, Qemu and other required packages ========="
        output ${LIGHT_BLUE} "Note: The package iptables-nft will conflict with iptables, please allow iptables-nft to install in order to use Virt-Manager's virutal ethernet feature."
        sleep 5
        pacman -S --needed qemu libvirt iptables-nft dnsmasq virt-manager virt-viewer bridge-utils dmidecode edk2-ovmf
        systemctl enable libvirtd
        output ${YELLOW} "====== Configuring KVM ======"
        sed -i '/unix_sock_group/s/^#//g' /etc/libvirt/libvirtd.conf
        sed -i '/unix_sock_rw_perms/s/^#//g' /etc/libvirt/libvirtd.conf
        virsh net-autostart default

        if [[ "${users[@]}" ]]; then
            output ${YELLOW} "====== Configuring additional users for libvirt ======"
            echo
            for i in "${users[@]}"; do
                usermod -a -G libvirt $i
            done
        fi
    fi
fi
#Graphics Card Driver Installer
while true; do
    read -p "$(output ${YELLOW} "What brand is your graphics? [I]ntel, [A]MD or [N]vidia?: ")" graphics
    case $graphics in
    I | i)
        output ${YELLOW} "========= Installing Intel Graphics ========="
        pacman -S --needed --noconfirm xf86-video-intel mesa vulkan-intel vulkan-driver lib32-mesa lib32-vulkan-intel vulkan-tools i2c-tools
        break;;
    A | a)
        output ${YELLOW} "========= Installing AMD Graphics ========="
        pacman -S --needed --noconfirm xf86-video-amdgpu mesa
        while true; do
            read -p "$(output ${YELLOW}"Are you using a [A]MD GPU or a [R]eadon GPU? ")" subgpu
            case $subgpu in
            A | a)
                pacman -S --needed --noconfirm amdvlk lib32-amdvlk vulkan-driver vulkan-tools i2c-tools
                break;;
            R | r)
                pacman -S --needed --noconfirm vulkan-radeon lib32-vulkan-radeon vulkan-driver vulkan-tools i2c-tools
                break;;
            *) output ${LIGHT_RED} "Invaild Input";;
            esac
        done
        break;;
    N | n)
        output ${YELLOW} "========= Installing Nvidia Graphics ========="
        pacman -S --needed --noconfirm nvidia nvidia-utils nvidia-settings lib32-nvidia-utils vulkan-tools i2c-tools vulkan-driver
        break;;
    *) output ${LIGHT_RED} "Invalid input" ;;
    esac
done

#Font packs install
output ${YELLOW} "====== Installing font packs ======"
pacman -S --needed --noconfirm dina-font tamsyn-font bdf-unifont ttf-bitstream-vera ttf-croscore ttf-dejavu ttf-droid gnu-free-fonts ttf-ibm-plex ttf-liberation noto-fonts ttf-roboto tex-gyre-fonts ttf-ubuntu-font-family ttf-anonymous-pro ttf-cascadia-code ttf-fantasque-sans-mono ttf-fira-mono ttf-hack ttf-fira-code ttf-inconsolata ttf-jetbrains-mono ttf-monofur adobe-source-code-pro-fonts cantarell-fonts inter-font ttf-opensans gentium-plus-font ttf-junicode adobe-source-han-sans-otc-fonts adobe-source-han-serif-otc-fonts noto-fonts-cjk noto-fonts-emoji

#Base user packages
output ${YELLOW} "====== Installing base user packages ====="
pacman -S --needed --noconfirm papirus-icon-theme syncthing discord htop emacs

#DE Install
while true; do
    output ${YELLOW} "What desktop environment do you want to install?"
    read -p "$(output ${YELLOW} "[X]fce, [G]nome, [K]DE, [C]innamon or [Q]tile?")" de
    case $de in
    X | x) # XFCE
        output ${YELLOW} "Installing XFCE and basic desktop apps"
        desktopenv="xfce"
        pacman -S --needed --noconfirm xorg lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings xfce4 xfce4-goodies arc-gtk-theme arc-icon-theme file-roller geeqie catfish xreader gparted pavucontrol qalculate-gtk deluge-gtk baobab
        systemctl enable lightdm
        pacman -R --noconfirm ristretto
        if [ "$use_bluetooth" = "yes" ]; then
            output ${YELLOW} "Installing GUI for bluetooth"
            pacman -S --noconfirm blueman
        fi
        break;;
    G | g) # Gnome
        output ${YELLOW} "Installing Gnome and basic desktop apps"
        desktopenv="gnome"
        pacman -S --needed --noconfirm xorg gdm gnome gnome-extra gnome-tweaks arc-gtk-theme arc-icon-theme file-roller gparted pavucontrol qalculate-gtk transmission-gtk baobab
        systemctl enable gdm
        if [ "$use_bluetooth" = "yes" ]; then
            output ${YELLOW} "Installing GUI for bluetooth"
            pacman -S --needed --noconfirm blueman
        fi
        break;;
    K | k) # KDE
        output ${YELLOW} "Installing KDE and basic desktop apps"
        desktopenv="kde"
        pacman -S --needed --noconfirm xorg sddm ark audiocd-kio breeze-gtk dolphin dragon elisa gwenview kate kdeconnect kde-gtk-config khotkeys kinfocenter kinit kio-fuse konsole kscreen kwallet-pam okular plasma-desktop plasma-disks plasma-nm plasma-pa powerdevil print-manager sddm-kcm solid spectacle xsettingsd plasma-browser-integration ksshaskpass pavucontrol-qt qalculate-qt qbittorrent filelight
        systemctl enable sddm
        if [ "$use_bluetooth" = "yes" ]; then
            output ${YELLOW} "Installing GUI for bluetooth"
            pacman -S --needed --noconfirm bluedevil
        fi
        if [[ "$is_laptop" = "yes" && "$is_touchscreen" = "yes" ]]; then
            output ${YELLOW} "Installing GUI for Wacom drivers"
            pacman -S --needed --noconfirm kcm-wacomtablet
        fi

        output ${YELLOW} "Adding Kwallet to PAM"
        sed -i '4s/.//' /etc/pam.d/sddm
        sed -i '15s/.//' /etc/pam.d/sddm
        break;;
    C | c) #Cinnamon
        output ${YELLOW} "Installing Cinnamon and basic desktop apps"
        desktopenv="cinnamon"
        pacman -S --needed --noconfirm xorg lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings cinnamon arc-gtk-theme arc-icon-theme gnome-shell file-roller nemo-fileroller gparted pavucontrol qalculate-gtk deluge-gtk baobab xreader
        systemctl enable lightdm
        if [ "$use_bluetooth" = "yes" ]; then
            output ${YELLOW} "Installing GUI for bluetooth"
            pacman -S --needed --noconfirm blueman
        fi
        break;;
    Q | q) #Qtile
        output ${YELLOW} "Installing Qtile and basic desktop apps"
        desktopenv="qtile"
        pacman -S --needed --noconfirm xorg qtile dunst feh betterlockscreen rofi brightnessctl
        if [ "$use_bluetooth" = "yes" ]; then
            output ${YELLOW} "Installing GUI for bluetooth"
            pacman -S --needed --noconfirm blueman
        fi
        break;;
    *) output ${LIGHT_RED} "Invalid input" ;;
    esac
done

output ${LIGHT_BLUE} "Saving Parameters for final step"
if [[ "${users[@]}" ]]; then echo "users=$users" >> ${SCRIPT_DIR}/sysconfig.conf; fi
echo "microcode=$microcode" >> ${SCRIPT_DIR}/sysconfig.conf
echo "use_graphics=$use_graphics" >> ${SCRIPT_DIR}/sysconfig.conf
echo "desktopenv=$desktopenv" >> ${SCRIPT_DIR}/sysconfig.conf
echo "is_touchscreen=$is_touchscreen" >> ${SCRIPT_DIR}/sysconfig.conf

if [ $(whoami) = "root"  ];
then
    for i in "${users[@]}"; do
        cp -R /root/aalis /home/$i/
        chown -R $i: /home/$i/aalis
    done
else
    output ${LIGHT_GREEN} "You are already a user, lets proceed with AUR installation"
fi

banner ${LIGHT_PURPLE} "SYSTEM READY FOR 2-user"
sleep 3
clear
