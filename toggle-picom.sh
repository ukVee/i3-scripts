if systemctl --user is-active --quiet picom.service; then
  systemctl --user stop picom.service
else
  systemctl --user start picom.service
fi
