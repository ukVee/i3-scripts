#!/bin/bash

# Shared monitor naming
source "$HOME/.config/hardware/monitors.sh"

# Default all workspaces to internal
for ws in {1..6}; do
    i3-msg "workspace $ws; move workspace to output $INTERNAL_DISPLAY" >/dev/null
done

# If external display is connected, assign 1–3 to external
if $EXT_MON_CONNECTED; then
    for ws in {1..3}; do
        i3-msg "workspace $ws; move workspace to output $EXTERNAL_DISPLAY" >/dev/null
    done
fi
