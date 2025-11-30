#!/bin/bash

# STEP 1: Default all workspaces to internal
for ws in {1..6}; do
    i3-msg "workspace $ws; move workspace to output eDP-2" >/dev/null
done

# STEP 2: If external display is connected, assign 1–3 to external
if xrandr | grep -q "HDMI-1-0 connected"; then
    for ws in {1..3}; do
        i3-msg "workspace $ws; move workspace to output HDMI-1-0" >/dev/null
    done
fi

