#!/bin/sh

lxsession &
xset r rate 300 50 &
nm-applet &
blueman-applet&
dunst &
feh --randomize --bg-fill ~/.config/wallpapers/wallpaper.png &
betterlockscreen -u ~/.config/Wallpapers &
xidlehook --timer 180 "brightnessctl set 5%" "brightnessctl set 100%" &
 xidlehook --not-when-audio --timer 300 "betterlockscreen -l dim -off 30"