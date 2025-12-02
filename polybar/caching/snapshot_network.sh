#!/usr/bin/env bash

source "$HOME/.config/polybar/helperscripts/status_common.sh"

CACHE_DIR="$HOME/.cache/polybar"
CACHE_FILE="$CACHE_DIR/peek_network.txt"
mkdir -p "$CACHE_DIR"

network_status >"$CACHE_FILE"
