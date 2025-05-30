#!/bin/bash
# System information script

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}║                      SYSTEM INFORMATION                     ║${NC}"
echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo

# System info
echo -e "${BLUE}🖥️  System:${NC} $(uname -sr)"
echo -e "${BLUE}🏠 Hostname:${NC} $(hostname)"
echo -e "${BLUE}👤 User:${NC} $(whoami)"
echo -e "${BLUE}⏰ Uptime:${NC} $(uptime -p)"
echo

# Hardware info
echo -e "${GREEN}💾 Memory Usage:${NC}"
free -h | awk 'NR==2{printf "   Used: %s/%s (%.2f%%)\n", $3,$2,$3*100/$2 }'
echo

echo -e "${GREEN}💿 Disk Usage:${NC}"
df -h | awk '$NF=="/"{printf "   Used: %s/%s (%s)\n", $3,$2,$5}'
echo

echo -e "${GREEN}🔥 CPU Usage:${NC}"
top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{printf "   Usage: %.1f%%\n", 100 - $1}'
echo

# Network info
echo -e "${CYAN}🌐 Network:${NC}"
ip route get 1.1.1.1 | awk '{print "   Interface: " $5}' 2>/dev/null
curl -s ifconfig.me | awk '{print "   Public IP: " $1}'
echo

# Hyprland info
if pgrep -x "Hyprland" > /dev/null; then
    echo -e "${YELLOW}🪟 Hyprland Status:${NC} Running"
    echo -e "${YELLOW}📺 Monitors:${NC} $(hyprctl monitors -j | jq length)"
    echo -e "${YELLOW}🏢 Workspaces:${NC} $(hyprctl workspaces -j | jq length)"
else
    echo -e "${RED}🪟 Hyprland Status:${NC} Not running"
fi
echo
