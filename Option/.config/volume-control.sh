#!/bin/bash
# Volume control script with notifications

case $1 in
    "up")
        wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
        ;;
    "down")
        wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
        ;;
    "mute")
        wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
        ;;
    *)
        echo "Usage: $0 {up|down|mute}"
        exit 1
        ;;
esac

# Get current volume
VOLUME=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2*100)}')
MUTED=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -o "MUTED")

# Show notification
if [ "$MUTED" = "MUTED" ]; then
    notify-send -t 2000 -h string:x-canonical-private-synchronous:volume "🔇 Volume Muted"
else
    notify-send -t 2000 -h string:x-canonical-private-synchronous:volume -h int:value:$VOLUME "🔊 Volume: ${VOLUME}%"
fi
