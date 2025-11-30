#!/bin/bash

# Auto-detect connected monitors
if xrandr | grep "DP-1 connected"; then
  xrandr --setprovideroutputsource NVIDIA-G0 modesetting
  xrandr --output eDP-1 --primary --mode 1920x1080 --rate 144 \
    --output DP-1 --left-of eDP-1 --mode 1920x1080 --rate 144
else
  xrandr --output eDP-2 --primary --auto --output HDMI-1-0 --off
fi
