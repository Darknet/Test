#!/bin/bash
# Wallpaper changer script

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"

if [ ! -d "$WALLPAPER_DIR" ]; then
    notify-send "Error" "Wallpaper directory not found: $WALLPAPER_DIR"
    exit 1
fi

# Get random wallpaper
WALLPAPER=$(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.bmp" \) | shuf -n 1)

if [ -z "$WALLPAPER" ]; then
    notify-send "Error" "No wallpapers found in $WALLPAPER_DIR"
    exit 1
fi

# Set wallpaper
swww img "$WALLPAPER" --transition-type wipe --transition-duration 2

# Show notification
notify-send "Wallpaper Changed" "$(basename "$WALLPAPER")"
