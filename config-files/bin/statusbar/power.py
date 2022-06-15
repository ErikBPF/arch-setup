#!/usr/bin/env python3

import os
import argparse
import subprocess

parser = argparse.ArgumentParser()
parser.add_argument('--c',
                    choices=('status', 'left-click', 'middle-click', 'right-click'),
                    dest='command',
                    default='status',
                    help='Allowed values are status, left-click, middle-click and right-click'
                    )
args = parser.parse_args()


if args.command == "status":
    print("襤", end="")
    subprocess.call(["setxkbmap", "us", "intl"])
if args.command == "left-click":
     subprocess.call([os.path.expanduser('~')+"/.config/rofi/powermenu/powermenu.sh"])
if args.command == "middle-click":
    print("Middle click")
if args.command == "right-click":
    print("Right click")