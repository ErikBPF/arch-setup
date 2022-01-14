#!/bin/bash

DISPLAY_COUNT=$(xrandr -d :0 -q | grep ' connected' | wc -l)

eval $(/usr/bin/gnome-keyring-daemon --start --components=gpg,pkcs11,secrets,ssh)
export $(gnome-keyring-daemon --start --components=pkcs11,secrets,ssh,gpg)
dbus-update-activation-environment --systemd DISPLAY &
setxkbmap us intl &
betterlockscreen -u $HOME/.config/wallpapers/ &

if [ "$DISPLAY_COUNT" == "3" ]; then
    xrandr --output DP-0 --off --output DP-1 --off --output HDMI-0 --mode 1920x1080 --pos 0x0 --rotate normal --output DP-2 --off --output DP-3 --mode 1920x1080 --pos 4480x0 --rotate normal --output DP-4 --primary --mode 2560x1080 --pos 1920x0 --rotate normal --output DP-5 --off --output USB-C-0 --off
fi