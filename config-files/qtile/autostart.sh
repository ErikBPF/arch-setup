#!/bin/sh

lxsession &
xset r rate 300 50 &
blueman-applet&
nm-applet &
pa-applet &
pulseeffects -w &
dunst &
feh --randomize --bg-fill ~/.config/wallpapers/wallpaper.png &
betterlockscreen -u ~/.config/wallpapers &
xidlehook --timer 180 "brightnessctl set 5%" "brightnessctl set 100%" &
xidlehook --not-when-audio --timer 300 "betterlockscreen -l dim -off 10" &