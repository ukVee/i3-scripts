#!/bin/bash
source "$HOME/.config/hardware/monitors.sh"

# Peek allowed ONLY in single-monitor (laptop) mode
if $EXT_MON_CONNECTED; then
  exit 1
fi

exit 0
