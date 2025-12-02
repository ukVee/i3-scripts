#!/usr/bin/env bash
set -euo pipefail

STATE_FILE="$HOME/.config/i3/scripts/session_management/state.json"
MAP_FILE="$HOME/.config/i3/scripts/session_management/app_commands.json"
MARK_FILE="/tmp/.i3_session_restored"

[ -f "$STATE_FILE" ] || exit 0
[ -f "$MAP_FILE" ] || exit 0
[ -f "$MARK_FILE" ] && exit 0

APP_CMDS=$(cat "$MAP_FILE")

existing=$(i3-msg -t get_tree)

current_counts=$(jq -n --argjson tree "$existing" '
  def leaves:
    (.nodes + .floating_nodes | map(leaves) | add) + [.];
  ($tree | leaves)
  | map(select(.window_properties.class? and .name?))
  | map({ws: (.workspace // .nodes[0].workspace // .name // "1"), class: .window_properties.class})
  | group_by(.ws)
  | map({workspace: .[0].ws, apps: (map(.class) | group_by(.) | map({class: .[0], count: length}))})
')

state=$(cat "$STATE_FILE")

join_ws() {
  jq -n --argjson saved "$state" --argjson cur "$current_counts" '
    def to_obj(a): reduce a[] as $i ({}; .[$i.workspace] = $i.apps);
    def to_countmap(a): reduce a[] as $i ({}; .[$i.class] = $i.count);
    def missing(saved; cur):
      to_obj(saved) as $s
      | to_obj(cur) as $c
      | reduce ($s|to_entries[]) as $ws ({}; 
          $ws.value as $apps |
          to_countmap($apps) as $need |
          to_countmap($c[$ws.key] // []) as $have |
          reduce ($need|to_entries[]) as $app (.;
            .[$ws.key] += [{class: $app.key, missing: ($app.value - ($have[$app.key] // 0))}] )
        );
    missing($saved; $cur)
  '
}

missing_json=$(join_ws)

launch_missing() {
  echo "$missing_json" | jq -c 'to_entries[]' | while read -r wsentry; do
    ws=$(echo "$wsentry" | jq -r '.key')
    echo "$wsentry" | jq -c '.value[] | select(.missing>0)' | while read -r appentry; do
      cls=$(echo "$appentry" | jq -r '.class')
      miss=$(echo "$appentry" | jq -r '.missing')
      cmd=$(echo "$APP_CMDS" | jq -r --arg c "$cls" '.[ $c ] // empty')
      [ -n "$cmd" ] || continue
      for _ in $(seq 1 "$miss"); do
        i3-msg "workspace $ws; exec --no-startup-id $cmd" >/dev/null
      done
    done
  done
}

launch_missing

touch "$MARK_FILE"
