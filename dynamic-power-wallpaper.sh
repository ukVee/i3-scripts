#!/usr/bin/env bash
# power-wallpaper.sh

WALLPAPER_DIR="$HOME/.steam/steam/steamapps/workshop/content/431960/3191719833"
AC_STATUS_FILE="/sys/class/power_supply/ADP1/online"

STATIC_CMD="feh --bg-fill ${WALLPAPER_DIR}/preview.gif"
ANIM_CMD_E="linux-wallpaperengine --screen-root eDP-2 -f 144 3191719833"
ANIM_CMD_DE="linux-wallpaperengine --silent --screen-root DP-3 -f 60 3191719833 --screen-root eDP-2 3191719833"

function set_main_wallpaper() {
    pkill -f linux-wallpaperengine
    pkill feh
    pkill picom

    if [[ $(cat "$AC_STATUS_FILE") -eq 1 ]]; then
        echo "[+] AC Power detected — starting animated wallpapers"

        # Start both displays if available
        if xrandr | grep -q "eDP-2 connected" && xrandr | grep -q "DP-3 connected"; then
            $ANIM_CMD_DE &
        else
	    $ANIM_CMD_E &
        fi

    else
        echo "[-] Battery power detected — switching to static wallpaper"
        feh --no-fehbg --bg-fill ${WALLPAPER_DIR}/preview.gif
    fi

    picom &
}

# Run once
set_main_wallpaper

# Poll every 5s for power changes
LAST_STATE=""
while true; do
    CURRENT_STATE=$(cat "$AC_STATUS_FILE" 2>/dev/null)
    if [[ "$CURRENT_STATE" != "$LAST_STATE" ]]; then
        set_main_wallpaper
        LAST_STATE="$CURRENT_STATE"
    fi
    sleep 5
done

