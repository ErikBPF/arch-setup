#!/usr/bin/env bash

set -e

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
VERSION=2.1.0
ONLINE_VERSION=$(curl -s https://gitlab.com/NovaViper/aalis/-/raw/main/VERSION.txt)

echo -ne "\e[95m"
echo    "---------------------------------"
echo    "         Preflight Check         "
echo -n "---------------------------------"
echo -e "\e[39m"
if [ -f ${SCRIPT_DIR}/script_funcs ]; then source ${SCRIPT_DIR}/script_funcs; output ${LIGHT_GREEN} "FOUND ${SCRIPT_DIR}/script_funcs!"; else echo -e "\e[31mCannot find ${SCRIPT_DIR}/script_funcs, cannot continue\e[39m"; sleep 2; exit 1; fi
output ${LIGHT_GREEN} "Preflight Check done! Moving on in 2 seconds"
sleep 2

banner ${LIGHT_PURPLE} "Checking if script is update to date..."
test_compare_versions $VERSION $ONLINE_VERSION
sleep 5

banner ${LIGHT_PURPLE} "Setting font size"
pacman -S --noconfirm terminus-font figlet
setfont ter-v22b
clear


output ${LIGHT_PURPLE} "$(figlet -pctf big "Advanced ArchLinux Install Script")"
output ${LIGHT_BLUE} "$(figlet -kctWf big "AALIS v${VERSION}")"
output ${LIGHT_RED} "$(figlet -kctWf term "~ AALIS in Archland! ~")"

if [[ "yes" == $(askYesNo "Would you like to start the install?") ]]; then
    output ${LIGHT_GREEN} "Lets begin the installation!"
else
    output  ${LIGHT_RED} "Ok, I'm leaving then!"
    exit 1;
fi

bash 0-preinstall.sh
arch-chroot /mnt /root/aalis/1-setup.sh
source /mnt/root/aalis/sysconfig.conf
for i in "${users[@]}"; do
    output ${YELLOW} "Running user setup for $i"
    arch-chroot /mnt /usr/bin/runuser -u $i -- /home/$i/aalis/2-user.sh

    output ${YELLOW} "Sending $i install log to main script directory"
    cp /mnt/home/$i/aalis/logs/user.log /mnt/root/aalis/logs/user_$i.log
    rm -Rf /mnt/home/$i/aalis
done
arch-chroot /mnt /root/aalis/3-post-setup.sh

banner ${LIGHT_PURPLE} "Cleaning up the system"
cp -R /mnt/root/aalis/logs ${SCRIPT_DIR}
rm -Rf /mnt/root/aalis

banner ${LIGHT_GREEN} "ALL DONE!! CHECK ALL OF THE LOG FILES IN THE LOG FOLDER AND CHECK" "FOR LINES WITH THE IMPORTANT TAG. THEN EJECT MEDIA AND RESTART!"
