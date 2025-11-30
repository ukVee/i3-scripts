if pgrep -x picom >/dev/null; then
  pkill -f picom
else
  picom &
fi
