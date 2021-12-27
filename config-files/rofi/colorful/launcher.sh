#!/usr/bin/env bash
theme="launcher"
dir="$HOME/.config/rofi/colorful/"

# dark
ALPHA="#00000000"
BG="#333333ff"
FG="#FFFFFFff"
SELECT="#101010ff"
ACCENT="#2aa198FF"

# overwrite colors file
cat > $dir/colors.rasi <<- EOF
	/* colors */

	* {
	  al:  $ALPHA;
	  bg:  $BG;
	  se:  $SELECT;
	  fg:  $FG;
	  ac:  $ACCENT;
	}
EOF

rofi -no-lazy-grab -show drun -modi drun -theme $dir/"$theme"
