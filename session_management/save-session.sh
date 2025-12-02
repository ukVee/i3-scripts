#!/usr/bin/env bash
set -euo pipefail

STATE_FILE="$HOME/.config/i3/scripts/session_management/state.json"
MARK_FILE="/tmp/.i3_session_restored"

tree_json=$(i3-msg -t get_tree)

jq -n --argjson tree "$tree_json" '
  def collect($ws):
    if .type == "workspace" then
      [ (.nodes + .floating_nodes // [])[] | collect(.name) ]
    elif .window_properties? then
      [{ws: $ws, class: .window_properties.class}]
    else
      [ (.nodes + .floating_nodes // [])[] | collect($ws) ] | add
    end;
  $tree | collect(null)
  | map(select(.class? and .ws?))
  | group_by(.ws)
  | map({
      workspace: .[0].ws,
      apps: (map(.class) | group_by(.) | map({class: .[0], count: length}))
    })
' > "$STATE_FILE"

rm -f "$MARK_FILE"

echo "Session saved to $STATE_FILE"
