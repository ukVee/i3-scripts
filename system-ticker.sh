#!/usr/bin/env bash

# ==============================
# Config
# ==============================
SCROLL_WIDTH=50
CHARS_PER_SEC=7
SLEEP_TIME=$(awk "BEGIN { printf \"%.4f\", 1 / $CHARS_PER_SEC }")

EVENT_PIPE="/tmp/polybar-ticker-$$"

# ==============================
# Setup FIFO + Cleanup
# ==============================

# Make sure no stale pipe exists
rm -f "$EVENT_PIPE"
mkfifo "$EVENT_PIPE"

# Open the FIFO read/write in this process so writers never block
# FD 3 will be our read handle in the main loop
exec 3<>"$EVENT_PIPE"

cleanup() {
  # Kill any children (journalctl, pipes, etc.)
  pkill -P $$ 2>/dev/null || true

  # Close FD and remove FIFO
  exec 3>&- 2>/dev/null || true
  exec 3<&- 2>/dev/null || true
  rm -f "$EVENT_PIPE"

  exit 0
}
trap cleanup EXIT INT TERM

# ==============================
# Scrolling logic
# ==============================

scroll_event() {
  local text="$1"
  local text_length=${#text}
  local total_positions=$((text_length + SCROLL_WIDTH))

  # Scroll from right to left
  for ((i = 0; i < total_positions; i++)); do
    local start=$i
    local visible_text=""

    # If we haven't completely scrolled past the text
    if ((start < text_length)); then
      local chars_to_show=$((text_length - start))
      if ((chars_to_show > SCROLL_WIDTH)); then
        chars_to_show=$SCROLL_WIDTH
      fi
      visible_text="${text:start:chars_to_show}"
    fi

    # Pad with spaces on the right
    while ((${#visible_text} < SCROLL_WIDTH)); do
      visible_text+=" "
    done

    # Print one line for polybar
    printf '%s\n' "$visible_text"
    sleep "$SLEEP_TIME"
  done

  # After scroll completes, clear the area once
  printf '%*s\n' "$SCROLL_WIDTH" " "
}

# ==============================
# Journal line parser
# ==============================

# Example journalctl short line:
# Nov 26 19:24:05 archlinux ukv[1785266]: test
parse_and_emit() {
  local line="$1"

  # Regex: month day time host source: message
  if [[ "$line" =~ ^[A-Z][a-z]+[[:space:]]+[0-9]+[[:space:]]+([0-9:]+)[[:space:]]+[^[:space:]]+[[:space:]]+([^:]+):[[:space:]]*(.*) ]]; then
    local time="${BASH_REMATCH[1]}"
    local source="${BASH_REMATCH[2]}"
    local message="${BASH_REMATCH[3]}"

    # Strip [PID] from source if present
    source="${source%%\[*}"

    # Trim whitespace from source and message
    source="$(echo "$source" | xargs)"
    message="$(echo "$message" | xargs)"

    # Skip empty messages
    [[ -z "$message" ]] && return 0

    # Write formatted event into the FIFO
    printf '[%s] %s: %s\n' "$time" "$source" "$message" >"$EVENT_PIPE"
  fi
}

# ==============================
# Event monitor
# ==============================

monitor_events() {
  {
    # 1) Docker errors
    journalctl -f -n 0 -p err -u docker.service 2>/dev/null &

    # 2) Systemd service state changes (Started/Stopped/etc.)
    journalctl -f -n 0 -t systemd 2>/dev/null &

    # Wait for both journalctl instances in this group
    wait
  } | while IFS= read -r line; do
    # If you want extra filtering like Started/Stopped, do it here,
    # not before parsing:
    if [[ "$line" =~ (Started|Stopped|Starting|Stopping|err|error|Error) ]]; then
      parse_and_emit "$line"
    fi
  done &
}

# ==============================
# Main
# ==============================

# Start the monitor in the background
monitor_events

# Main loop: read events from FIFO and scroll them
while true; do
  # -t 0.5 → don't block forever if no events; keeps script responsive
  if IFS= read -t 0.5 -r event <&3; then
    # Ignore empty lines
    [[ -z "$event" ]] && continue
    scroll_event "$event"
  else
    # No new event in the last 0.5s:
    # Do nothing → Polybar keeps last drawn content.
    :
  fi
done
