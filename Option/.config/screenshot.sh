#!/bin/bash
# Screenshot script for Hyprland

SCREENSHOT_DIR="$HOME/Pictures/Screenshots"
mkdir -p "$SCREENSHOT_DIR"

case $1 in
    "region")
        grim -g "$(slurp)" "$SCREENSHOT_DIR/screenshot-$(date +%Y%m%d-%H%M%S).png"
        ;;
    "window")
        grim -g "$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')" "$SCREENSHOT_DIR/screenshot-$(date +%Y%m%d-%H%M%S).png"
        ;;
    "fullscreen")
        grim "$SCREENSHOT_DIR/screenshot-$(date +%Y%m%d-%H%M%S).png"
        ;;
    *)
        echo "Usage: $0 {region|window|fullscreen}"
        exit 1
        ;;
esac

# Show notification
notify-send "Screenshot taken" "Saved to $SCREENSHOT_DIR"
