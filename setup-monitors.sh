#!/bin/bash

# Shared monitor naming
source "$HOME/.config/hardware/monitors.sh"

if $EXT_MON_CONNECTED; then
  xrandr --setprovideroutputsource NVIDIA-G0 modesetting
  xrandr --output "$INTERNAL_DISPLAY" --primary --mode 1920x1080 --rate 144 \
         --output "$EXTERNAL_DISPLAY" --left-of "$INTERNAL_DISPLAY" --mode 1920x1080 --rate 144
else
  xrandr --output "$INTERNAL_DISPLAY" --primary --auto \
         --output "$EXTERNAL_DISPLAY" --off
fi
