#!/usr/bin/env bash

# Variable declarations
use_crypt=""
use_swap=""
use_btrfs=""
is_laptop=""
diskUUID=""
RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
RAM_MB=$(expr $RAM_KB / 1024)
RAM_GB=$(expr $RAM_MB / 1024)
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

#Enable logging!
mkdir ${SCRIPT_DIR}/logs
touch ${SCRIPT_DIR}/logs/preinstall.log
exec &> >(tee ${SCRIPT_DIR}/logs/preinstall.log)

echo -ne "\e[95m"
echo    "---------------------------------"
echo    "         Preflight Check         "
echo -n "---------------------------------"
echo -e "\e[39m"
if [ -f ${SCRIPT_DIR}/script_funcs ]; then source ${SCRIPT_DIR}/script_funcs; output ${LIGHT_GREEN} "FOUND ${SCRIPT_DIR}/script_funcs!"; else echo -e "\e[31mCannot find ${SCRIPT_DIR}/script_funcs, cannot continue\e[39m"; sleep 2; exit 1; fi
output ${LIGHT_GREEN} "Preflight Check done! Moving on in 2 seconds"
sleep 2

banner ${LIGHT_PURPLE} "Configuring Pacman"
sed -i 's/^#Color/Color/' /etc/pacman.conf
sed -i 's/^#Para/Para/' /etc/pacman.conf


banner ${LIGHT_PURPLE} "Starting Preinstallation Phase"
if [ -f ${SCRIPT_DIR}/sysconfig.conf ]; then output ${LIGHT_BLUE} "Removing old sysconfig.conf"; rm ${SCRIPT_DIR}/sysconfig.conf; fi

if [[ "yes" == $(askYesNo "Are you installing ArchLinux on a laptop?") ]]; then is_laptop="yes"; fi

if [[ "yes" == $(askYesNo "Do you want to use SWAP?") ]]; then use_swap="yes"; fi

if [[ "yes" == $(askYesNo "Do you want to use LUKS disk encryption?") ]]; then use_crypt="yes"; fi

banner ${LIGHT_PURPLE} "Select your disk to format"
lsblk
while true; do
    echo "Please enter disk to work on: (example /dev/sda)"
    read DISK
    if [[ ! "$DISK" = "" ]]; then
        output ${LIGHT_RED} "THIS WILL FORMAT AND DELETE ALL DATA ON THE DISK$"
        if [[ "no" == $(askYesNo "Are you sure you want to continue?" ${LIGHT_RED}) ]]; then
            output ${LIGHT_RED} "Stopping script"
            exit 1;
        else
            output ${LIGHT_GREEN} "Ok, lets get started!"
            sleep 1
            clear
            break;
        fi
    else
        output ${LIGHT_RED} "This cannot be blank! Please try again!"
    fi
done

banner ${LIGHT_PURPLE} "Formatting disk, ${DISK}..."
#Unmount everything
if grep -qs '/mnt' /proc/mounts; then
    output ${YELLOW} "Attempting to unmount"
    umount /mnt/* -A -f
    umount /mnt -A -f
    if [[ "$use_crypt" = "yes"  ]]; then cryptsetup close cryptroot; fi
fi

# disk prep
sgdisk -Z ${DISK} # zap all on disk
sgdisk -a 2048 -o ${DISK} # new gpt disk 2048 alignment

# create partitions
if [ -d /sys/firmware/efi ]; then
    output ${YELLOW} "Creating UEFI boot partition"
    sgdisk -n 1::+512M --typecode=1:ef00 ${DISK} # partition 1 (UEFI Boot Partition)
    sgdisk -n 2::-0 --typecode=2:8300 ${DISK} # partition 2 (Root), default start, remaining
    makePartitions "uefi" ${DISK}
else
    output ${YELLOW} "Creating BIOS boot partition"
    sgdisk -n 1::+1M --typecode=1:ef02 ${DISK} # partition 1 (BIOS Boot Partition)
    sgdisk -n 2::+512M --typecode=2:ef00 ${DISK} # partition 2 (UEFI Boot Partition)
    sgdisk -n 3::-0 --typecode=3:8300 ${DISK} # partition 3 (Root), default start, remaining
    sgdisk -A 1:set:2 ${DISK}
    makePartitions "bios" ${DISK}
fi

output ${LIGHT_BLUE} "Lets confirm if everything is correct!"
output ${YELLOW} "Checking if there are any mounts"
if ! grep -qs '/mnt' /proc/mounts; then
    output ${LIGHT_RED} "Drive is not mounted; cannot continue!"
    exit 1
fi

#Output mounts
lsblk
if [[ "yes" = $(askYesNo "Does everything look correct?") ]]; then
    output ${LIGHT_GREEN} "Ok, moving on!"
else
    output ${LIGHT_RED} "Something must've gone wrong, cannot continue!"
    exit 1
fi

banner ${LIGHT_PURPLE} "Arch Install on Main Drive"
pacstrap /mnt --noconfirm --needed base base-devel linux linux-firmware git
genfstab -U /mnt >> /mnt/etc/fstab

# Add swap to fstab, so it KEEPS working after installation.
if [[ "$use_swap" = "yes"  ]]; then echo "/swap/swapfile    none    swap    defaults,pri=10     0   0" >> /mnt/etc/fstab; fi

output ${LIGHT_BLUE} "Lets do one final check to make sure your mounts are correct! I will display the fstab in 5 seconds."
sleep 5
cat /mnt/etc/fstab
if [[ "yes" = $(askYesNo "Does your fstab look correct?") ]]; then
    output ${LIGHT_GREEN} "Ok, moving on!"
else
    output ${LIGHT_RED} "Something must've gone wrong, cannot continue!"
    exit 1
fi

output ${LIGHT_BLUE} "Saving Parameters for next step"
touch ${SCRIPT_DIR}/sysconfig.conf
echo "use_swap=$use_swap" >> ${SCRIPT_DIR}/sysconfig.conf
echo "use_btrfs=$use_btrfs" >> ${SCRIPT_DIR}/sysconfig.conf
echo "use_crypt=$use_crypt" >> ${SCRIPT_DIR}/sysconfig.conf
echo "is_laptop=$is_laptop" >> ${SCRIPT_DIR}/sysconfig.conf
echo "diskUUID=$diskUUID" >> ${SCRIPT_DIR}/sysconfig.conf
cp -R ${SCRIPT_DIR} /mnt/root/aalis

banner ${LIGHT_GREEN} "SYSTEM READY FOR 1-setup"
sleep 3
clear
