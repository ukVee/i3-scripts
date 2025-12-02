#!/usr/bin/env bash
# set_wallpaper.sh — choose wallpaper depending on number of monitors

source "$HOME/.config/hardware/monitors.sh"

MON_COUNT=$(xrandr --query | grep " connected" | wc -l)

WALL_DIR="/mnt/backup/photos/wallpapers"
# you may adjust WALL_SINGLE and WALL_MULTI or pick randomly
WALL_SINGLE="$WALL_DIR/cherry_blossum_min.jpg"
WALL_LEFT="$WALL_DIR/left_monitor.jpg"
WALL_RIGHT="$WALL_DIR/right_monitor.jpg"

# for debug
# echo "Monitors: $MON_LIST"
# echo "Count: $MON_COUNT"

if ! $EXT_MON_CONNECTED; then
  # single monitor case
  feh --no-fehbg --bg-fill "$WALL_SINGLE"
elif [ "$MON_COUNT" -ge 2 ]; then
  # two or more monitors: take first two monitors
  # you could handle more monitors if you want
  feh --no-fehbg --bg-max "$WALL_LEFT" "$WALL_RIGHT"
else
  # fallback: single
  feh --no-fehbg --bg-fill "$WALL_SINGLE"
fi

exit 0
