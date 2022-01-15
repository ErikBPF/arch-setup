#!/usr/bin/env -S bash -e

# Cleaning the TTY.
clear

# Pretty print (function).
print () {
    echo -e "\e[1m\e[93m[ \e[92m•\e[93m ] \e[4m$1\e[0m"
}

# Virtualization check (function).
virt_check () {
    hypervisor=$(systemd-detect-virt)
    case $hypervisor in
        kvm )   print "KVM has been detected."
                print "Installing guest tools."
                pacstrap /mnt qemu-guest-agent
                print "Enabling specific services for the guest tools."
                systemctl enable qemu-guest-agent --root=/mnt &>/dev/null
                ;;
        vmware  )   print "VMWare Workstation/ESXi has been detected."
                    print "Installing guest tools."
                    pacstrap /mnt open-vm-tools
                    print "Enabling specific services for the guest tools."
                    systemctl enable vmtoolsd --root=/mnt &>/dev/null
                    systemctl enable vmware-vmblock-fuse --root=/mnt &>/dev/null
                    ;;
        oracle )    print "VirtualBox has been detected."
                    print "Installing guest tools."
                    pacstrap /mnt virtualbox-guest-utils
                    print "Enabling specific services for the guest tools."
                    systemctl enable vboxservice --root=/mnt &>/dev/null
                    ;;
        microsoft ) print "Hyper-V has been detected."
                    print "Installing guest tools."
                    pacstrap /mnt hyperv
                    print "Enabling specific services for the guest tools."
                    systemctl enable hv_fcopy_daemon --root=/mnt &>/dev/null
                    systemctl enable hv_kvp_daemon --root=/mnt &>/dev/null
                    systemctl enable hv_vss_daemon --root=/mnt &>/dev/null
                    ;;
        * ) ;;
    esac
}

# Selecting a kernel to install (function). 
kernel_selector () {
    print "List of kernels:"
    print "1) Stable: Vanilla Linux kernel with a few specific Arch Linux patches applied"
    print "2) Hardened: A security-focused Linux kernel"
    print "3) LTS: Long-term support (LTS) Linux kernel"
    print "4) Zen: A Linux kernel optimized for desktop usage"
    read -r -p "Insert the number of the corresponding kernel: " choice
    case $choice in
        1 ) kernel="linux"
            ;;
        2 ) kernel="linux-hardened"
            ;;
        3 ) kernel="linux-lts"
            ;;
        4 ) kernel="linux-zen"
            ;;
        * ) print "You did not enter a valid selection."
            kernel_selector
    esac
}

# Selecting a way to handle internet connection (function). 
network_selector () {
    print "Network utilities:"
    print "1) IWD: iNet wireless daemon is a wireless daemon for Linux written by Intel (WiFi-only)"
    print "2) NetworkManager: Universal network utility to automatically connect to networks (both WiFi and Ethernet)"
    print "3) wpa_supplicant: Cross-platform supplicant with support for WEP, WPA and WPA2 (WiFi-only, a DHCP client will be automatically installed as well)"
    print "4) dhcpcd: Basic DHCP client (Ethernet only or VMs)"
    print "5) I will do this on my own (only advanced users)"
    read -r -p "Insert the number of the corresponding networking utility: " choice
    case $choice in
        1 ) print "Installing IWD."    
            pacstrap /mnt iwd
            print "Enabling IWD."
            systemctl enable iwd --root=/mnt &>/dev/null
            ;;
        2 ) print "Installing NetworkManager."
            pacstrap /mnt networkmanager
            print "Enabling NetworkManager."
            systemctl enable NetworkManager --root=/mnt &>/dev/null
            ;;
        3 ) print "Installing wpa_supplicant and dhcpcd."
            pacstrap /mnt wpa_supplicant dhcpcd
            print "Enabling wpa_supplicant and dhcpcd."
            systemctl enable wpa_supplicant --root=/mnt &>/dev/null
            systemctl enable dhcpcd --root=/mnt &>/dev/null
            ;;
        4 ) print "Installing dhcpcd."
            pacstrap /mnt dhcpcd
            print "Enabling dhcpcd."
            systemctl enable dhcpcd --root=/mnt &>/dev/null
            ;; 
        5 ) ;;
        * ) print "You did not enter a valid selection."
            network_selector
    esac
}

# Setting up a password for the LUKS Container (function).
password_selector () {
    read -r -s -p "Insert password for the LUKS container (you're not going to see the password): " password
    if [ -z "$password" ]; then
        print "You need to enter a password for the LUKS Container in order to continue."
        password_selector
    fi
    echo -n "$password" | cryptsetup luksFormat "$CRYPTROOT" -d -
    echo -n "$password" | cryptsetup open "$CRYPTROOT" cryptroot -d -
    BTRFS="/dev/mapper/cryptroot"
}

# Microcode detector (function).
microcode_detector () {
    CPU=$(grep vendor_id /proc/cpuinfo)
    if [[ $CPU == *"AuthenticAMD"* ]]; then
        print "An AMD CPU has been detected, the AMD microcode will be installed."
        microcode="amd-ucode"
    else
        print "An Intel CPU has been detected, the Intel microcode will be installed."
        microcode="intel-ucode"
    fi
}

# Setting up the hostname (function).
hostname_selector () {
    read -r -p "Please enter the hostname: " hostname
    if [ -z "$hostname" ]; then
        print "You need to enter a hostname in order to continue."
        hostname_selector
    fi
    echo "$hostname" > /mnt/etc/hostname
}

# Setting up the locale (function).
locale_selector () {
    echo "en_US.UTF-8 UTF-8"  > /mnt/etc/locale.gen
    echo "LANG=en_US.UTF-8" > /mnt/etc/locale.conf
}

# Setting up the keyboard layout (function).
keyboard_selector () {
    echo "KEYMAP=us" > /mnt/etc/vconsole.conf
}

gpu_installer () (
    GPU=$(lspci | grep VGA)
    if [[ $GPU == *"NVIDIA Corporation"* ]]; then
        pacstrap /mnt nvidia nvidia-utils nvidia-settings
    fi
    if [[ $GPU == *"Intel Corporation"* ]]; then
        pacstrap /mnt xf86-video-intel mesa
    fi
)

# Selecting the target for the installation.
print "Welcome to arch-erik a script made in order to simplify the process of installing Arch Linux."
PS3="Please select the disk where Arch Linux is going to be installed: "
select ENTRY in $(lsblk -dpnoNAME|grep -P "/dev/sd|nvme|vd");
do
    DISK=$ENTRY
    print "Installing Arch Linux on $DISK."
    break
done

# Deleting old partition scheme.
read -r -p "This will delete the current partition table on $DISK. Do you agree [y/N]? " response
response=${response,,}
if [[ "$response" =~ ^(yes|y)$ ]]; then
    print "Wiping $DISK."
    wipefs -af "$DISK" &>/dev/null
    sgdisk -Zo "$DISK" &>/dev/null
else
    print "Quitting."
    exit
fi

# Creating a new partition scheme.
print "Creating the partitions on $DISK."
parted -s "$DISK" \
    mklabel gpt \
    mkpart ESP fat32 1MiB 513MiB \
    set 1 esp on \
    mkpart CRYPTROOT 513MiB 100% \

ESP="/dev/disk/by-partlabel/ESP"
CRYPTROOT="/dev/disk/by-partlabel/CRYPTROOT"

# Informing the Kernel of the changes.
print "Informing the Kernel about the disk changes."
partprobe "$DISK"

# Formatting the ESP as FAT32.
print "Formatting the EFI Partition as FAT32."
mkfs.fat -F 32 $ESP &>/dev/null

# Creating a LUKS Container for the root partition.
print "Creating LUKS Container for the root partition."
password_selector

# Formatting the LUKS Container as BTRFS.
print "Formatting the LUKS container as BTRFS."
mkfs.btrfs $BTRFS &>/dev/null
mount $BTRFS /mnt

# Creating BTRFS subvolumes.
print "Creating BTRFS subvolumes."
for volume in @ @home @root @srv @snapshots @var_log @var_pkgs
do
    btrfs su cr /mnt/$volume
done

# Mounting the newly created subvolumes.
umount /mnt
print "Mounting the newly created subvolumes."
mount -o ssd,noatime,compress-force=zstd:3,discard=async,subvol=@ $BTRFS /mnt
mkdir -p /mnt/{home,root,srv,.snapshots,/var/log,/var/cache/pacman/pkg,boot}
mount -o ssd,noatime,compress-force=zstd:3,discard=async,subvol=@home $BTRFS /mnt/home
mount -o ssd,noatime,compress-force=zstd:3,discard=async,subvol=@root $BTRFS /mnt/root
mount -o ssd,noatime,compress-force=zstd:3,discard=async,subvol=@srv $BTRFS /mnt/srv
mount -o ssd,noatime,compress-force=zstd:3,discard=async,subvol=@snapshots $BTRFS /mnt/.snapshots
mount -o ssd,noatime,compress-force=zstd:3,discard=async,subvol=@var_log $BTRFS /mnt/var/log
mount -o ssd,noatime,compress-force=zstd:3,discard=async,subvol=@var_pkgs $BTRFS /mnt/var/cache/pacman/pkg
chattr +C /mnt/var/log
mount $ESP /mnt/boot/

# Checking the microcode to install.
microcode_detector

# Virtualization check.
virt_check

# Pacstrap (setting up a base sytem onto the new root).
print "Installing the base system (it may take a while)."
pacstrap /mnt $microcode base base-devel linux linux-firmware 
# Setting up the hostname.
hostname_selector

# Setting root password.
print "Setting root password."
arch-chroot /mnt /bin/passwd

read -r -p "Please enter name for a user account (enter empty to not create one): " username
# Setting user password.
if [ -n "$username" ]; then
    print "Adding the user $username to the system with root privilege."
    arch-chroot /mnt useradd -m -G wheel -s /bin/bash "$username"
    sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /mnt/etc/sudoers
    print "Setting user password for $username." 
    arch-chroot /mnt /bin/passwd "$username"
fi

pacstrap /mnt reflector git gnupg networkmanager dhclient dialog wpa_supplicant wireless_tools netctl inetutils openssh btrfs-progs grub grub-btrfs rsync efibootmgr snapper reflector snap-pac zram-generator

# Generating /etc/fstab.
print "Generating a new fstab."
genfstab -U /mnt >> /mnt/etc/fstab

# Setting username.


# Setting up the locale.
locale_selector

# Setting up keyboard layout.
keyboard_selector

# Setting hosts file.
print "Setting hosts file."
cat > /mnt/etc/hosts <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   $hostname.localdomain   $hostname
EOF

# Configuring /etc/mkinitcpio.conf.
print "Configuring /etc/mkinitcpio.conf."
cat > /mnt/etc/mkinitcpio.conf <<EOF
HOOKS=(base systemd autodetect keyboard sd-vconsole modconf block sd-encrypt filesystems)
COMPRESSION=(zstd)
EOF

# Setting up LUKS2 encryption in grub.
print "Setting up grub config."
UUID=$(blkid -s UUID -o value $CRYPTROOT)
sed -i "s,^GRUB_CMDLINE_LINUX=\"\",GRUB_CMDLINE_LINUX=\"rd.luks.name=$UUID=cryptroot root=$BTRFS\",g" /mnt/etc/default/grub

gpu_installer

print "installing grafical packages"
pacstrap /mnt xorg git make xdg-user-dirs xdg-utils lightdm lightdm-slick-greeter

# Configuring the system.    
arch-chroot /mnt /bin/bash -e <<EOF
    # Setting up timezone.
    echo "Setting up the timezone."
    ln -sf /usr/share/zoneinfo/$(curl -s http://ip-api.com/line?fields=timezone) /etc/localtime &>/dev/null
    
    # Setting up clock.
    echo "Setting up the system clock."
    hwclock --systohc
    
    # Generating locales.
    echo "Generating locales."
    locale-gen &>/dev/null
    
    # Generating a new initramfs.
    echo "Creating a new initramfs."
    mkinitcpio -P &>/dev/null
    
    # Snapper configuration
    echo "Configuring Snapper."
    umount /.snapshots
    rm -r /.snapshots
    snapper --no-dbus -c root create-config /
    btrfs subvolume delete /.snapshots &>/dev/null
    mkdir /.snapshots
    mount -a
    chmod 750 /.snapshots
    
    # Installing GRUB.
    echo "Installing GRUB on /boot."
    grub-install --target=x86_64-efi --efi-directory=/boot/ --bootloader-id=GRUB &>/dev/null
    # Creating grub config file.
    echo "Creating GRUB config file."
    grub-mkconfig -o /boot/grub/grub.cfg &>/dev/null
EOF



# Boot backup hook.
print "Configuring /boot backup when pacman transactions are made."
mkdir /mnt/etc/pacman.d/hooks
cat > /mnt/etc/pacman.d/hooks/50-bootbackup.hook <<EOF
[Trigger]
Operation = Upgrade
Operation = Install
Operation = Remove
Type = Path
Target = usr/lib/modules/*/vmlinuz
[Action]
Depends = rsync
Description = Backing up /boot...
When = PostTransaction
Exec = /usr/bin/rsync -a --delete /boot /.bootbackup
EOF

# ZRAM configuration.
print "Configuring ZRAM."
cat > /mnt/etc/systemd/zram-generator.conf <<EOF
[zram0]
zram-fraction = 1
max-zram-size = 8192
EOF

# Pacman eye-candy features.
print "Enabling colours and animations in pacman."
sed -i 's/#Color/Color\nILoveCandy/' /mnt/etc/pacman.conf

# Enabling various services.
print "Enabling Reflector, automatic snapshots, BTRFS scrubbing and systemd-oomd."
for service in reflector.timer snapper-timeline.timer snapper-cleanup.timer btrfs-scrub@-.timer btrfs-scrub@home.timer btrfs-scrub@var-log.timer btrfs-scrub@\\x2esnapshots.timer grub-btrfs.path systemd-oomd lightdm NetworkManager wpa_supplicant
do
    systemctl enable "$service" --root=/mnt &>/dev/null
done

# Setting user environment
if [ -n "$username" ]; then
    pacman -Sy git make --needed --noconfirm
    repository="https://github.com/ErikBPF/arch-setup"
    docFolder="/home/$username/Documents"
    localFolder="$docFolder/arch-setup"
    mkdir -p "/mnt$localFolder"
    git clone "$repository" "/mnt$localFolder"
    chmod a+rwx "/mnt$localFolder/setup.sh"
    arch-chroot /mnt $localFolder/setup.sh
fi

# Finishing up.
print "Done, you may now wish to reboot (further changes can be done by chrooting into /mnt)."
exit