#!/usr/bin/env bash
# Intelligent layout launcher for i3
# Applies the given layout to the current workspace and spawns only what it requires

set -euo pipefail

LAYOUT_FILE="$HOME/.config/i3/layouts/workspace-firefox.json"
CONKY_CFG="$HOME/.config/conky/conkyInfobarv2"

# --- Detect current workspace dynamically ---
CURRENT_WS=$(i3-msg -t get_workspaces | jq -r '.[] | select(.focused==true).name')

# --- Parse required window classes from layout file ---
# This extracts the "class" field from every "swallows" entry in the JSON layout.
readarray -t REQUIRED_CLASSES < <(jq -r '.. | .swallows? // empty | .[]?.class? // empty | gsub("\\^|\\$"; "")' "$LAYOUT_FILE" | sort -u)

# --- Apply layout to the current workspace ---
i3-msg "workspace $CURRENT_WS; append_layout $LAYOUT_FILE" >/dev/null

# --- Function to spawn the correct window type ---
spawn_window() {
    local class="$1"

    case "$class" in
        firefox)
            firefox &
            ;;
        kitty)
            kitty &
            ;;
        ConkyTechBar)
            conky -c "$CONKY_CFG" &
            ;;
        *)
            echo "No spawn rule for class '$class'" >&2
            ;;
    esac
}

# --- Get currently open window classes in this workspace ---
readarray -t EXISTING_CLASSES < <(i3-msg -t get_tree | jq -r \
    --arg WS "$CURRENT_WS" \
    '[recurse(.nodes[]?, .floating_nodes[]?) | select(.name? and .window_properties.class?) 
     | select(.workspace? == $WS or (.nodes[].workspace? == $WS)) 
     | .window_properties.class] | unique | .[]')

# --- Launch only missing windows ---
for class in "${REQUIRED_CLASSES[@]}"; do
    if ! printf '%s\n' "${EXISTING_CLASSES[@]}" | grep -qx "$class"; then
        echo "Launching new window for $class..."
        spawn_window "$class"
        sleep 0.3  # give i3 a moment to attach it properly
    fi
done

