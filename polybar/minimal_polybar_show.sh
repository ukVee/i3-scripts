#!/bin/bash

# Check if peek mode is allowed
~/.config/i3/scripts/polybar/should_minimal_polybar_keybind_work.sh || exit 0

# Prevent re-entrant launches while key is held using a lockfile tied to PID
LOCKFILE="/tmp/polybar-peek.lock"
if [ -f "$LOCKFILE" ] && kill -0 "$(cat "$LOCKFILE")" 2>/dev/null; then
  exit 0
fi

# cache current battery and wifi info before starting process.
~/.config/i3/scripts/polybar/caching/snapshot_battery.sh
~/.config/i3/scripts/polybar/caching/snapshot_network.sh

# Launch minimal "peek" Polybar config
polybar -c ~/.config/polybar/peek.ini peek &
PEEK_PID=$!
echo "$PEEK_PID" >"$LOCKFILE"

# Apply rhombus mask
$HOME/.config/polybar/apply-peek-mask.sh
