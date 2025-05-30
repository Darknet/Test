#!/bin/bash
# Power menu script using wofi

options="⏻ Shutdown\n🔄 Reboot\n🔒 Lock\n🚪 Logout\n😴 Suspend\n💤 Hibernate"

chosen=$(echo -e "$options" | wofi --dmenu --prompt "Power Menu" --width 300 --height 200)

case $chosen in
    "⏻ Shutdown")
        systemctl poweroff
        ;;
    "🔄 Reboot")
        systemctl reboot
        ;;
    "🔒 Lock")
        swaylock
        ;;
    "🚪 Logout")
        hyprctl dispatch exit
        ;;
    "😴 Suspend")
        systemctl suspend
        ;;
    "💤 Hibernate")
        systemctl hibernate
        ;;
esac
