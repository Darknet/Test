#!/bin/bash

# Enhanced Hyprland Installation Script - Fixed Version
# Fixes: SDDM installation, Waybar autostart, Rofi/Wofi, Waydroid errors

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/tmp/hyprland-install.log"
CONFIG_DIR="$HOME/.config"

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
    exit 1
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

# Check if running on Arch Linux
check_arch() {
    if ! command -v pacman &> /dev/null; then
        error "This script is designed for Arch Linux systems only."
    fi
}

# Detect GPU type
detect_gpu() {
    local gpu_type=""
    
    if lspci | grep -i nvidia &> /dev/null; then
        if lspci | grep -i intel &> /dev/null || lspci | grep -i amd &> /dev/null; then
            gpu_type="hybrid"
        else
            gpu_type="nvidia"
        fi
    elif lspci | grep -i amd &> /dev/null; then
        gpu_type="amd"
    elif lspci | grep -i intel &> /dev/null; then
        gpu_type="intel"
    else
        gpu_type="unknown"
    fi
    
    echo "$gpu_type"
}

# User prompts
ask_user_preferences() {
    echo -e "${BLUE}=== Hyprland Installation Configuration ===${NC}"
    
    # GPU Configuration
    local detected_gpu=$(detect_gpu)
    log "Detected GPU type: $detected_gpu"
    
    case $detected_gpu in
        "nvidia")
            echo -e "${YELLOW}NVIDIA GPU detected.${NC}"
            read -p "Install NVIDIA drivers for Wayland/Hyprland? (y/n): " install_nvidia
            ;;
        "hybrid")
            echo -e "${YELLOW}Hybrid GPU setup detected (NVIDIA + Intel/AMD).${NC}"
            read -p "Configure for hybrid GPU setup? (y/n): " install_nvidia
            ;;
        *)
            install_nvidia="n"
            ;;
    esac
    
    # Waydroid
    read -p "Install Waydroid (Android emulation)? (y/n): " install_waydroid
    
    # Display Manager
    read -p "Install and configure SDDM display manager? (y/n): " install_sddm
    
    # Export variables
    export INSTALL_NVIDIA="${install_nvidia:-n}"
    export INSTALL_WAYDROID="${install_waydroid:-n}"
    export INSTALL_SDDM="${install_sddm:-y}"
}

# Install display manager
install_display_manager() {
    if [[ "$INSTALL_SDDM" == "y" ]]; then
        log "Installing and configuring SDDM..."
        
        # Install SDDM
        sudo pacman -S --needed --noconfirm sddm qt5-graphicaleffects qt5-quickcontrols2 qt5-svg
        
        # Enable SDDM service
        sudo systemctl enable sddm.service
        
        # Configure SDDM for Wayland
        sudo mkdir -p /etc/sddm.conf.d
        sudo tee /etc/sddm.conf.d/10-wayland.conf > /dev/null <<EOF
[General]
DisplayServer=wayland
GreeterEnvironment=QT_WAYLAND_SHELL_INTEGRATION=layer-shell

[Wayland]
SessionDir=/usr/share/wayland-sessions
EOF

        # Install SDDM theme
        if ! pacman -Qs sddm-sugar-candy-git &> /dev/null; then
            yay -S --needed --noconfirm sddm-sugar-candy-git || warning "Failed to install SDDM theme"
        fi
        
        log "SDDM installed and configured"
    fi
}

# Install base packages
install_base_packages() {
    log "Installing base packages..."
    
    # Update system first
    sudo pacman -Syu --noconfirm
    
    local packages=(
        # Hyprland and Wayland essentials
        "hyprland"
        "xdg-desktop-portal-hyprland"
        "xdg-desktop-portal-gtk"
        "qt5-wayland"
        "qt6-wayland"
        
        # Status bar and launcher
        "waybar"
        "wofi"
        "rofi-wayland"
        
        # Notifications and wallpaper
        "dunst"
        "swww"
        "mako"
        
        # Screenshot and clipboard
        "grim"
        "slurp"
        "wl-clipboard"
        "cliphist"
        
        # Audio
        "pipewire"
        "pipewire-alsa"
        "pipewire-pulse"
        "pipewire-jack"
        "wireplumber"
        "pavucontrol"
        
        # Fonts
        "ttf-font-awesome"
        "ttf-jetbrains-mono-nerd"
        "noto-fonts"
        "noto-fonts-emoji"
        "ttf-dejavu"
        
        # Terminal and shell
        "kitty"
        "fish"
        "starship"
        
        # File utilities
        "eza"
        "bat"
        "ripgrep"
        "fd"
        "fzf"
        "tree"
        
        # File manager
        "thunar"
        "thunar-archive-plugin"
        "thunar-volman"
        "tumbler"
        "ffmpegthumbnailer"
        
        # Archive support
        "file-roller"
        "unzip"
        "unrar"
        "p7zip"
        
        # Media
        "mpv"
        "imv"
        "playerctl"
        
        # Network
        "networkmanager"
        "network-manager-applet"
        
        # Bluetooth
        "bluez"
        "bluez-utils"
        "blueman"
        
        # System utilities
        "polkit-gnome"
        "gnome-keyring"
        "brightnessctl"
        "pamixer"
        
        # Development
        "git"
        "neovim"
        "code"
        
        # System info
        "neofetch"
        "htop"
        "btop"
    )
    
    sudo pacman -S --needed --noconfirm "${packages[@]}" || error "Failed to install base packages"
    
    # Enable essential services
    sudo systemctl enable NetworkManager.service
    sudo systemctl enable bluetooth.service
}

# Install AUR helper and AUR packages
install_aur_packages() {
    log "Installing AUR packages..."
    
    # Install yay if not present
    if ! command -v yay &> /dev/null; then
        log "Installing yay AUR helper..."
        cd /tmp
        git clone https://aur.archlinux.org/yay.git
        cd yay
        makepkg -si --noconfirm
        cd "$SCRIPT_DIR"
    fi
    
    local aur_packages=(
        "hyprpicker"
        "wlogout"
        "swaylock-effects"
        "wlsunset"
        "nwg-look"
        "bibata-cursor-theme"
        "hyprshot"
        "waybar-hyprland-git"
    )
    
    for package in "${aur_packages[@]}"; do
        yay -S --needed --noconfirm "$package" || warning "Failed to install $package"
    done
}

# Install NVIDIA drivers
install_nvidia_drivers() {
    if [[ "$INSTALL_NVIDIA" == "y" ]]; then
        log "Installing NVIDIA drivers for Wayland..."
        
        local nvidia_packages=(
            "nvidia-dkms"
            "nvidia-utils"
            "nvidia-settings"
            "libva-nvidia-driver"
            "egl-wayland"
        )
        
        sudo pacman -S --needed --noconfirm "${nvidia_packages[@]}"
        
        # Configure NVIDIA for Wayland
        sudo tee /etc/modprobe.d/nvidia.conf > /dev/null <<EOF
options nvidia_drm modeset=1 fbdev=1
options nvidia NVreg_PreserveVideoMemoryAllocations=1
EOF
        
        # Add NVIDIA modules to initramfs
        sudo sed -i 's/MODULES=()/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf
        
        # Update initramfs
        sudo mkinitcpio -P
        
        # Create NVIDIA Wayland rules
        sudo tee /etc/udev/rules.d/61-gdm.rules > /dev/null <<EOF
# disable Wayland on Hi1710 chipsets
ATTR{vendor}=="0x19e5", ATTR{device}=="0x1711", RUN+="/usr/lib/gdm-runtime-config set daemon WaylandEnable false"
# disable Wayland when using the proprietary nvidia driver
DRIVER=="nvidia", RUN+="/usr/lib/gdm-runtime-config set daemon WaylandEnable false"
# But enable for SDDM
DRIVER=="nvidia", ENV{SDDM_WAYLAND}="1"
EOF
        
        log "NVIDIA drivers installed. Reboot required."
    fi
}

# Install Waydroid with proper error handling
install_waydroid_support() {
    if [[ "$INSTALL_WAYDROID" == "y" ]]; then
        log "Installing Waydroid..."
        
        # Check if kernel supports waydroid
        if ! zgrep -q "CONFIG_ASHMEM=y\|CONFIG_ASHMEM=m" /proc/config.gz 2>/dev/null; then
            warning "Kernel may not support Waydroid. Installing anyway..."
        fi
        
        # Install waydroid and dependencies
        yay -S --needed --noconfirm waydroid python-pyclip || {
            error "Failed to install Waydroid. This may be due to kernel compatibility issues."
        }
        
        # Install waydroid image
        sudo waydroid init || warning "Waydroid init failed. Run 'sudo waydroid init' manually after reboot."
        
        log "Waydroid installed. Note: Waydroid requires specific kernel modules and may not work on all systems."
    fi
}

# Create Hyprland configuration
create_hyprland_config() {
    log "Creating Hyprland configuration..."
    
    mkdir -p "$CONFIG_DIR/hypr"
    
    cat > "$CONFIG_DIR/hypr/hyprland.conf" <<'EOF'
# Hyprland Configuration

# Monitor configuration
monitor=,preferred,auto,1

# Autostart applications
exec-once = waybar
exec-once = dunst
exec-once = swww init && swww img ~/Pictures/Wallpapers/default.jpg
exec-once = /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1
exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
exec-once = systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
exec-once = wl-paste --type text --watch cliphist store
exec-once = wl-paste --type image --watch cliphist store

# Input configuration
input {
    kb_layout = us
    kb_variant =
    kb_model =
    kb_options =
    kb_rules =
    follow_mouse = 1
    touchpad {
        natural_scroll = true
        disable_while_typing = true
        tap-to-click = true
    }
    sensitivity = 0
}

# General settings
general {
    gaps_in = 5
    gaps_out = 10
    border_size = 2
    col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
    col.inactive_border = rgba(595959aa)
    layout = dwindle
    allow_tearing = false
}

# Decoration
decoration {
    rounding = 10
    blur {
        enabled = true
        size = 8
        passes = 1
        new_optimizations = true
    }
    drop_shadow = true
    shadow_range = 4
    shadow_render_power = 3
    col.shadow = rgba(1a1a1aee)
}

# Animations
animations {
    enabled = true
    bezier = myBezier, 0.05, 0.9, 0.1, 1.05
    animation = windows, 1, 7, myBezier
    animation = windowsOut, 1, 7, default, popin 80%
    animation = border, 1, 10, default
    animation = borderangle, 1, 8, default
    animation = fade, 1, 7, default
    animation = workspaces, 1, 6, default
}

# Layout
dwindle {
    pseudotile = true
    preserve_split = true
}

master {
    new_is_master = true
}

# Gestures
gestures {
    workspace_swipe = false
}

# Misc
misc {
    force_default_wallpaper = 0
    disable_hyprland_logo = true
}

# Window rules
windowrule = float, ^(pavucontrol)$
windowrule = float, ^(blueman-manager)$
windowrule = float, ^(nm-connection-editor)$
windowrule = float, ^(nwg-look)$
windowrule = float, ^(qt5ct)$
windowrule = float, ^(qt6ct)$

# Key bindings
$mainMod = SUPER

# Applications
bind = $mainMod, Q, exec, kitty
bind = $mainMod, C, killactive,
bind = $mainMod, M, exit,
bind = $mainMod, E, exec, thunar
bind = $mainMod, V, togglefloating,
bind = $mainMod, R, exec, wofi --show drun
bind = $mainMod, D, exec, rofi -show drun
bind = $mainMod, P, pseudo,
bind = $mainMod, J, togglesplit,
bind = $mainMod, F, fullscreen,
bind = $mainMod, L, exec, swaylock

# Move focus with mainMod + arrow keys
bind = $mainMod, left, movefocus, l
bind = $mainMod, right, movefocus, r
bind = $mainMod, up, movefocus, u
bind = $mainMod, down, movefocus, d

# Move focus with mainMod + vim keys
bind = $mainM
bind = $mainMod, h, movefocus, l
bind = $mainMod, l, movefocus, r
bind = $mainMod, k, movefocus, u
bind = $mainMod, j, movefocus, d

# Switch workspaces with mainMod + [0-9]
bind = $mainMod, 1, workspace, 1
bind = $mainMod, 2, workspace, 2
bind = $mainMod, 3, workspace, 3
bind = $mainMod, 4, workspace, 4
bind = $mainMod, 5, workspace, 5
bind = $mainMod, 6, workspace, 6
bind = $mainMod, 7, workspace, 7
bind = $mainMod, 8, workspace, 8
bind = $mainMod, 9, workspace, 9
bind = $mainMod, 0, workspace, 10

# Move active window to a workspace with mainMod + SHIFT + [0-9]
bind = $mainMod SHIFT, 1, movetoworkspace, 1
bind = $mainMod SHIFT, 2, movetoworkspace, 2
bind = $mainMod SHIFT, 3, movetoworkspace, 3
bind = $mainMod SHIFT, 4, movetoworkspace, 4
bind = $mainMod SHIFT, 5, movetoworkspace, 5
bind = $mainMod SHIFT, 6, movetoworkspace, 6
bind = $mainMod SHIFT, 7, movetoworkspace, 7
bind = $mainMod SHIFT, 8, movetoworkspace, 8
bind = $mainMod SHIFT, 9, movetoworkspace, 9
bind = $mainMod SHIFT, 0, movetoworkspace, 10

# Example special workspace (scratchpad)
bind = $mainMod, S, togglespecialworkspace, magic
bind = $mainMod SHIFT, S, movetoworkspace, special:magic

# Scroll through existing workspaces with mainMod + scroll
bind = $mainMod, mouse_down, workspace, e+1
bind = $mainMod, mouse_up, workspace, e-1

# Move/resize windows with mainMod + LMB/RMB and dragging
bindm = $mainMod, mouse:272, movewindow
bindm = $mainMod, mouse:273, resizewindow

# Screenshot bindings
bind = , Print, exec, hyprshot -m output
bind = $mainMod, Print, exec, hyprshot -m window
bind = $mainMod SHIFT, Print, exec, hyprshot -m region

# Audio control
bind = , XF86AudioRaiseVolume, exec, pamixer -i 5
bind = , XF86AudioLowerVolume, exec, pamixer -d 5
bind = , XF86AudioMute, exec, pamixer -t
bind = , XF86AudioPlay, exec, playerctl play-pause
bind = , XF86AudioPause, exec, playerctl play-pause
bind = , XF86AudioNext, exec, playerctl next
bind = , XF86AudioPrev, exec, playerctl previous

# Brightness control
bind = , XF86MonBrightnessUp, exec, brightnessctl set +10%
bind = , XF86MonBrightnessDown, exec, brightnessctl set 10%-

# Clipboard history
bind = $mainMod, V, exec, cliphist list | wofi --dmenu | cliphist decode | wl-copy

# Color picker
bind = $mainMod SHIFT, C, exec, hyprpicker -a

# Logout menu
bind = $mainMod SHIFT, E, exec, wlogout
EOF

    # Add NVIDIA specific configuration if needed
    if [[ "$INSTALL_NVIDIA" == "y" ]]; then
        cat >> "$CONFIG_DIR/hypr/hyprland.conf" <<'EOF'

# NVIDIA specific settings
env = LIBVA_DRIVER_NAME,nvidia
env = XDG_SESSION_TYPE,wayland
env = GBM_BACKEND,nvidia-drm
env = __GLX_VENDOR_LIBRARY_NAME,nvidia
env = WLR_NO_HARDWARE_CURSORS,1
env = NVIDIA_MODESET,1
env = NVIDIA_DRM_MODESET,1
env = __GL_GSYNC_ALLOWED,0
env = __GL_VRR_ALLOWED,0
env = WLR_DRM_NO_ATOMIC,1

cursor {
    no_hardware_cursors = true
}
EOF
    fi
}

# Create Waybar configuration
create_waybar_config() {
    log "Creating Waybar configuration..."
    
    mkdir -p "$CONFIG_DIR/waybar"
    
    cat > "$CONFIG_DIR/waybar/config.jsonc" <<'EOF'
{
    "layer": "top",
    "position": "top",
    "height": 35,
    "spacing": 4,
    "margin-top": 5,
    "margin-left": 10,
    "margin-right": 10,
    "modules-left": [
        "hyprland/workspaces",
        "hyprland/mode",
        "hyprland/scratchpad"
    ],
    "modules-center": [
        "hyprland/window"
    ],
    "modules-right": [
        "idle_inhibitor",
        "pulseaudio",
        "network",
        "cpu",
        "memory",
        "temperature",
        "backlight",
        "battery",
        "clock",
        "tray"
    ],
    
    "hyprland/workspaces": {
        "disable-scroll": true,
        "all-outputs": true,
        "warp-on-scroll": false,
        "format": "{icon}",
        "format-icons": {
            "1": "1",
            "2": "2",
            "3": "3",
            "4": "4",
            "5": "5",
            "6": "6",
            "7": "7",
            "8": "8",
            "9": "9",
            "10": "10",
            "urgent": "",
            "focused": "",
            "default": ""
        }
    },
    
    "hyprland/mode": {
        "format": "<span style=\"italic\">{}</span>"
    },
    
    "hyprland/scratchpad": {
        "format": "{icon} {count}",
        "show-empty": false,
        "format-icons": ["", ""],
        "tooltip": true,
        "tooltip-format": "{app}: {title}"
    },
    
    "hyprland/window": {
        "format": "{}",
        "max-length": 50,
        "separate-outputs": true
    },
    
    "idle_inhibitor": {
        "format": "{icon}",
        "format-icons": {
            "activated": "",
            "deactivated": ""
        }
    },
    
    "tray": {
        "spacing": 10
    },
    
    "clock": {
        "timezone": "America/New_York",
        "tooltip-format": "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>",
        "format-alt": "{:%Y-%m-%d}",
        "format": "{:%H:%M}"
    },
    
    "cpu": {
        "format": "{usage}% ",
        "tooltip": false,
        "on-click": "kitty -e htop"
    },
    
    "memory": {
        "format": "{}% ",
        "on-click": "kitty -e htop"
    },
    
    "temperature": {
        "thermal-zone": 2,
        "hwmon-path": "/sys/class/hwmon/hwmon2/temp1_input",
        "critical-threshold": 80,
        "format-critical": "{temperatureC}°C {icon}",
        "format": "{temperatureC}°C {icon}",
        "format-icons": ["", "", ""]
    },
    
    "backlight": {
        "format": "{percent}% {icon}",
        "format-icons": ["", "", "", "", "", "", "", "", ""],
        "on-scroll-up": "brightnessctl set +5%",
        "on-scroll-down": "brightnessctl set 5%-"
    },
    
    "battery": {
        "states": {
            "warning": 30,
            "critical": 15
        },
        "format": "{capacity}% {icon}",
        "format-charging": "{capacity}% ",
        "format-plugged": "{capacity}% ",
        "format-alt": "{time} {icon}",
        "format-icons": ["", "", "", "", ""]
    },
    
    "network": {
        "format-wifi": "{essid} ({signalStrength}%) ",
        "format-ethernet": "{ipaddr}/{cidr} ",
        "tooltip-format": "{ifname} via {gwaddr} ",
        "format-linked": "{ifname} (No IP) ",
        "format-disconnected": "Disconnected ⚠",
        "format-alt": "{ifname}: {ipaddr}/{cidr}",
        "on-click-right": "nm-connection-editor"
    },
    
    "pulseaudio": {
        "format": "{volume}% {icon} {format_source}",
        "format-bluetooth": "{volume}% {icon} {format_source}",
        "format-bluetooth-muted": " {icon} {format_source}",
        "format-muted": " {format_source}",
        "format-source": "{volume}% ",
        "format-source-muted": "",
        "format-icons": {
            "headphone": "",
            "hands-free": "",
            "headset": "",
            "phone": "",
            "portable": "",
            "car": "",
            "default": ["", "", ""]
        },
        "on-click": "pavucontrol",
        "on-scroll-up": "pamixer -i 5",
        "on-scroll-down": "pamixer -d 5"
    }
}
EOF

    # Waybar CSS
    cat > "$CONFIG_DIR/waybar/style.css" <<'EOF'
* {
    border: none;
    border-radius: 0;
    font-family: "JetBrainsMono Nerd Font", "Font Awesome 6 Free";
    font-size: 13px;
    min-height: 0;
}

window#waybar {
    background-color: rgba(30, 30, 46, 0.9);
    border-radius: 15px;
    color: #cdd6f4;
    transition-property: background-color;
    transition-duration: 0.5s;
}

button {
    box-shadow: inset 0 -3px transparent;
    border: none;
    border-radius: 0;
}

#workspaces button {
    padding: 0 8px;
    background-color: transparent;
    color: #cdd6f4;
    border-radius: 10px;
    margin: 3px;
}

#workspaces button:hover {
    background: rgba(205, 214, 244, 0.2);
}

#workspaces button.active {
    background-color: #89b4fa;
    color: #1e1e2e;
}

#workspaces button.urgent {
    background-color: #f38ba8;
    color: #1e1e2e;
}

#mode {
    background-color: #64727D;
    border-bottom: 3px solid #ffffff;
}

#clock,
#battery,
#cpu,
#memory,
#disk,
#temperature,
#backlight,
#network,
#pulseaudio,
#wireplumber,
#custom-media,
#tray,
#mode,
#idle_inhibitor,
#scratchpad,
#mpd {
    padding: 0 10px;
    color: #cdd6f4;
    margin: 3px 0;
    border-radius: 10px;
}

#window,
#workspaces {
    margin: 0 4px;
}

.modules-left > widget:first-child > #workspaces {
    margin-left: 0;
}

.modules-right > widget:last-child > #workspaces {
    margin-right: 0;
}

#clock {
    background-color: #89b4fa;
    color: #1e1e2e;
    font-weight: bold;
}

#battery {
    background-color: #a6e3a1;
    color: #1e1e2e;
}

#battery.charging, #battery.plugged {
    background-color: #a6e3a1;
    color: #1e1e2e;
}

@keyframes blink {
    to {
        background-color: #f38ba8;
        color: #1e1e2e;
    }
}

#battery.critical:not(.charging) {
    background-color: #f38ba8;
    color: #1e1e2e;
    animation-name: blink;
    animation-duration: 0.5s;
    animation-timing-function: linear;
    animation-iteration-count: infinite;
    animation-direction: alternate;
}

label:focus {
    background-color: #000000;
}

#cpu {
    background-color: #fab387;
    color: #1e1e2e;
}

#memory {
    background-color: #f9e2af;
    color: #1e1e2e;
}

#disk {
    background-color: #f2cdcd;
    color: #1e1e2e;
}

#backlight {
    background-color: #cba6f7;
    color: #1e1e2e;
}

#network {
    background-color: #94e2d5;
    color: #1e1e2e;
}

#network.disconnected {
    background-color: #f38ba8;
    color: #1e1e2e;
}

#pulseaudio {
    background-color: #f5c2e7;
    color: #1e1e2e;
}

#pulseaudio.muted {
    background-color: #6c7086;
    color: #cdd6f4;
}

#temperature {
    background-color: #f38ba8;
    color: #1e1e2e;
}

#temperature.critical {
    background-color: #eba0ac;
    color: #1e1e2e;
}

#tray {
    background-color: #45475a;
}

#tray > .passive {
    -gtk-icon-effect: dim;
}

#tray > .needs-attention {
    -gtk-icon-effect: highlight;
    background-color: #f38ba8;
}

#idle_inhibitor {
    background-color: #45475a;
}

#idle_inhibitor.activated {
    background-color: #f9e2af;
    color: #1e1e2e;
}

#scratchpad {
    background-color: #6c7086;
}

#scratchpad.empty {
    background-color: transparent;
}
EOF
}

# Create Wofi configuration
create_wofi_config() {
    log "Creating Wofi configuration..."
    
    mkdir -p "$CONFIG_DIR/wofi"
    
    cat > "$CONFIG_DIR/wofi/config" <<'EOF'
width=600
height=400
location=center
show=drun
prompt=Search Applications...
filter_rate=100
allow_markup=true
no_actions=true
halign=fill
orientation=vertical
content_halign=fill
insensitive=true
allow_images=true
image_size=40
gtk_dark=true
key_expand=Tab
EOF

    cat > "$CONFIG_DIR/wofi/style.css" <<'EOF'
window {
    margin: 0px;
    border: 2px solid #89b4fa;
    background-color: #1e1e2e;
    border-radius: 15px;
    font-family: "JetBrainsMono Nerd Font";
}

#input {
    padding: 8px 12px;
    margin: 8px;
    border: none;
    color: #cdd6f4;
    font-weight: bold;
    background-color: #313244;
    outline: none;
    border-radius: 10px;
    font-size: 14px;
}

#input:focus {
    border: 2px solid #89b4fa;
}

#inner-box {
    margin: 5px;
    border: none;
    color: #cdd6f4;
    font-weight: bold;
    background-color: #1e1e2e;
    border-radius: 10px;
}

#outer-box {
    margin: 5px;
    border: none;
    border-radius: 15px;
    background-color: #1e1e2e;
}

#scroll {
    margin: 0px;
    border: none;
    border-radius: 10px;
}

#text {
    margin: 5px;
    border: none;
    color: #cdd6f4;
}

#text:selected {
    color: #1e1e2e;
    background-color: #89b4fa;
    border-radius: 8px;
}

#entry {
    margin: 2px;
    border: none;
    border-radius: 8px;
    background-color: transparent;
    padding: 5px;
}

#entry:selected {
    background-color: #89b4fa;
    color: #1e1e2e;
}

#entry:hover {
    background-color: #313244;
}
EOF
}

# Create Dunst configuration
create_dunst_config() {
    log "Creating Dunst configuration..."
    
    mkdir -p "$CONFIG_DIR/dunst"
    
    cat > "$CONFIG_DIR/dunst/dunstrc" <<'EOF'
[global]
    monitor = 0
    follow = mouse
    width = 350
    height = 300
    origin = top-right
    offset = 10x50
    scale = 0
    notification_limit = 0
    progress_bar = true
    progress_bar_height = 10
    progress_bar_frame_width = 1
    progress_bar_min_width = 150
    progress_bar_max_width = 300
    indicate_hidden = yes
    transparency = 10
    separator_height = 2
    padding = 8
    horizontal_padding = 8
    text_icon_padding = 0
    frame_width = 2
    frame_color = "#89b4fa"
    separator_color = frame
    sort = yes
    idle_threshold = 120
    font = JetBrainsMono Nerd Font 10
    line_height = 0
    markup = full
    format = "<b>%s</b>\n%b"
    alignment = left
    vertical_alignment = center
    show_age_threshold = 60
    ellipsize = middle
    ignore_newline = no
    stack_duplicates = true
    hide_duplicate_count = false
    show_indicators = yes
    icon_position = left
    min_icon_size = 32
    max_icon_size = 64
    icon_path = /usr/share/icons/Adwaita/16x16/status/:/usr/share/icons/Adwaita/16x16/devices/
    sticky_history = yes
    history_length = 20
    dmenu = /usr/bin/wofi --show dmenu
    browser = /usr/bin/xdg-open
    always_run_script = true
    title = Dunst
    class = Dunst
    corner_radius = 10
    ignore_dbusclose = false
    force_xwayland = false
    force_xinerama = false
    mouse_left_click = close_current
    mouse_middle_click = do_action, close_current
    mouse_right_click = close_all

[experimental]
    per_monitor_dpi = false

[urgency_low]
    background = "#1e1e2e"
    foreground = "#cdd6f4"
    timeout = 5
    icon = dialog-information

[urgency_normal]
    background = "#1e1e2e"
    foreground = "#cdd6f4"
    timeout = 10
    icon = dialog-information

[urgency_critical]
    background = "#f38ba8"
    foreground = "#1e1e2e"
    frame_color = "#fab387"
    timeout = 0
    icon = dialog-warning
EOF
}

# Create Kitty configuration
create_kitty_config() {
    log "Creating Kitty configuration..."
    
    mkdir -p "$CONFIG_DIR/kitty"
    
    cat > "$CONFIG_DIR/kitty/kitty.conf" <<'EOF'
# Font configuration
font_family JetBrainsMono Nerd Font
bold_font auto
italic_font auto
bold_italic_font auto
font_size 12.0

# Cursor
cursor_shape block
cursor_blink_interval 0.5
cursor_stop_blinking_after 15.0

# Scrollback
scrollback_lines 10000
scrollback_pager less --chop-long-lines --RAW-CONTROL-CHARS +INPUT_LINE_NUMBER

# Mouse
mouse_hide_wait 3.0
url_color #89b4fa
url_style curly
open_url_modifiers kitty_mod
open_url_with default
copy_on_select no
strip_trailing_spaces never

# Performance tuning
repaint_delay 10
input_delay 3
sync_to_monitor yes

# Terminal bell
enable_audio_bell no
visual_bell_duration 0.0

# Window layout
remember_window_size yes
initial_window_width 640
initial_window_height 400
enabled_layouts *
window_resize_step_cells 2
window_resize_step_lines 2
window_border_width 1pt
draw_minimal_borders yes
window_margin_width 0
single_window_margin_width -1
window_padding_width 5
placement_strategy center
active_border_color #89b4fa
inactive_border_color #45475a

# Tab bar
tab_bar_edge bottom
tab_bar_margin_width 0.0
tab_bar_style fade
tab_bar_min_tabs 2
tab_fade 0.25 0.5 0.75 1
tab_separator " ┇"
active_tab_foreground #1e1e2e
active_tab_background #89b4fa
inactive_tab_foreground #cdd6f4
inactive_tab_background #45475a

# Catppuccin Mocha theme
foreground #cdd6f4
background #1e1e2e
selection_foreground #1e1e2e
selection_background #f5e0dc

# Cursor colors
cursor #f5e0dc
cursor_text_color #1e1e2e

# URL underline color when hovering with mouse
url_color #f5e0dc

# Kitty window border colors
active_border_color #b4befe
inactive_border_color #6c7086
bell_border_color #f9e2af

# OS Window titlebar colors
wayland_titlebar_color system
macos_titlebar_color system

# Tab bar colors
active_tab_foreground #11111b
active_tab_background #cba6f7
inactive_tab_foreground #cdd6f4
inactive_tab_background #181825
tab_bar_background #11111b

# Colors for marks (marked text in the terminal)
mark1_foreground #1e1e2e
mark1_background #b4befe
mark2_foreground #1e1e2e
mark2_background #cba6f7
mark3_foreground #1e1e2e
mark3_background #74c7ec

# The 16 terminal colors

# black
color0 #45475a
color8 #585b70

# red
color1 #f38ba8
color9 #f38ba8

# green
color2 #a6e3a1
color10 #a6e3a1

# yellow
color3 #f9e2af
color11 #f9e2af

# blue
color4 #89b4fa
color12 #89b4fa

# magenta
color5 #f5c2e7
color13 #f5c2e7

# cyan
color6 #94e2d5
color14 #94e2d5

# white
color7 #bac2de
color15 #a6adc8

# Key mappings
kitty_mod ctrl+shift

# Clipboard
map kitty_mod+c copy_to_clipboard
map kitty_mod+v paste_from_clipboard
map kitty_mod+s paste_from_selection
map kitty_mod+o pass_selection_to_program

# Scrolling
map kitty_mod+up scroll_line_up
map kitty_mod+k scroll_line_up
map kitty_mod+down scroll_line_down
map kitty_mod+j scroll_line_down
map kitty_mod+page_up scroll_page_up
map kitty_mod+page_down scroll_page_down
map kitty_mod+home scroll_home
map kitty_mod+end scroll_end
map kitty_mod+h show_scrollback

# Window management
map kitty_mod+enter new_window
map kitty_mod+n new_os_window
map kitty_mod+w close_window
map kitty_mod+] next_window
map kitty_mod+[ previous_window
map kitty_mod+f move_window_forward
map kitty_mod+b move_window_backward
map kitty_mod+` move_window_to_top
map kitty_mod+r start_resizing_window
map kitty_mod+1 first_window
map kitty_mod+2 second_window
map kitty_mod+3 third_window
map kitty_mod+4 fourth_window
map kitty_mod+5 fifth_window
map kitty_mod+6 sixth_window
map kitty_mod+7 seventh_window
map kitty_mod+8 eighth_window
map kitty_mod+9 ninth_window
map kitty_mod+0 tenth_window

# Tab management
map kitty_mod+right next_tab
map kitty_mod+left previous_tab
map kitty_mod+t new_tab
map kitty_mod+q close_tab
map kitty_mod+. move_tab_forward
map kitty_mod+, move_tab_backward
map kitty_mod+alt+t set_tab_title

# Layout management
map kitty_mod+l next_layout

# Font sizes
map kitty_mod+equal change_font_size all +2.0
map kitty_mod+plus change_font_size all +2.0
map kitty_mod+kp_add change_font_size all +2.0
map kitty_mod+minus change_font_size all -2.0
map kitty_mod+kp_subtract change_font_size all -2.0
map kitty_mod+backspace change_font_size all 0

# Select and act on visible text
map kitty_mod+e kitten hints
map kitty_mod+p>f kitten hints --type path --program -
map kitty_mod+p>shift+f kitten hints --type path
map kitty_mod+p>l kitten hints --type line --program -
map kitty_mod+p>w kitten hints --type word --program -
map kitty_mod+p>h kitten hints --type hash --program -
map kitty_mod+p>n kitten hints --type linenum

# Miscellaneous
map kitty_mod+f11 toggle_fullscreen
map kitty_mod+f10 toggle_maximized
map kitty_mod+u kitten unicode_input
map kitty_mod+f2 edit_config_file
map kitty_mod+escape kitty_shell window

# Sending arbitrary text on key presses
map kitty_mod+alt+1 send_text all \x01
map kitty_mod+alt+2 send_text all \x02
map kitty_mod+alt+3 send_text all \x03

# Symbol mapping (special font symbol support)
symbol_map U+E0A0-U+E0A3,U+E0C0-U+E0C7 PowerlineSymbols
EOF
}

# Create Fish shell configuration
create_fish_config() {
    log "Creating Fish shell configuration..."
    
    mkdir -p "$CONFIG_DIR/fish/functions"
    
    cat > "$CONFIG_DIR/fish/config.fish" <<'EOF'
# Fish shell configuration

# Disable greeting
set fish_greeting ""

# Initialize Starship prompt
if command -v starship >/dev/null
    starship init fish | source
end

# Environment variables
set -gx EDITOR nvim
set -gx BROWSER firefox
set -gx TERMINAL kitty
set -gx PAGER less

# Add local bin to PATH
if test -d ~/.local/bin
    fish_add_path ~/.local/bin
end

# Aliases
alias ls='eza --color=always --group-directories-first --icons'
alias ll='eza -alF --color=always --group-directories-first --icons'
alias la='eza -a --color=always --group-directories-first --icons'
alias l='eza -F --color=always --group-directories-first --icons'
alias lt='eza -aT --color=always --group-directories-first --icons'
alias l.='eza -a | grep -E "^\."'

alias cat='bat --style=plain'
alias grep='rg'
alias find='fd'
alias du='dust'
alias df='duf'
alias ps='procs'

# Git aliases
alias g='git'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias gs='git status'
alias gd='git diff'
alias gco='git checkout'
alias gb='git branch'
alias glog='git log --oneline --graph --decorate'

# System aliases
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ~='cd ~'

# Package management
alias pacin='sudo pacman -S'
alias pacup='sudo pacman -Syu'
alias pacse='pacman -Ss'
alias pacrem='sudo pacman -R'
alias pacclean='sudo pacman -Sc'
alias yayin='yay -S'
alias yayup='yay -Syu'
alias yayrem='yay -R'

# Hyprland specific
alias hypreload='hyprctl reload'
alias hyprinfo='hyprctl info'
alias hyprmon='hyprctl monitors'

# System monitoring
alias top='btop'
alias htop='btop'
alias cpu='btop'
alias mem='btop'

# Quick edits
alias hyprconf='$EDITOR ~/.config/hypr/hyprland.conf'
alias wayconf='$EDITOR ~/.config/waybar/config.jsonc'
alias fishconf='$EDITOR
alias fishconf='$EDITOR ~/.config/fish/config.fish'
alias kittyconf='$EDITOR ~/.config/kitty/kitty.conf'

# Functions
function mkcd
    mkdir -p $argv[1] && cd $argv[1]
end

function extract
    if test -f $argv[1]
        switch $argv[1]
            case '*.tar.bz2'
                tar xjf $argv[1]
            case '*.tar.gz'
                tar xzf $argv[1]
            case '*.bz2'
                bunzip2 $argv[1]
            case '*.rar'
                unrar x $argv[1]
            case '*.gz'
                gunzip $argv[1]
            case '*.tar'
                tar xf $argv[1]
            case '*.tbz2'
                tar xjf $argv[1]
            case '*.tgz'
                tar xzf $argv[1]
            case '*.zip'
                unzip $argv[1]
            case '*.Z'
                uncompress $argv[1]
            case '*.7z'
                7z x $argv[1]
            case '*'
                echo "'$argv[1]' cannot be extracted via extract()"
        end
    else
        echo "'$argv[1]' is not a valid file"
    end
end

# Colorize man pages
set -gx LESS_TERMCAP_mb (printf "\033[01;31m")
set -gx LESS_TERMCAP_md (printf "\033[01;31m")
set -gx LESS_TERMCAP_me (printf "\033[0m")
set -gx LESS_TERMCAP_se (printf "\033[0m")
set -gx LESS_TERMCAP_so (printf "\033[01;44;33m")
set -gx LESS_TERMCAP_ue (printf "\033[0m")
set -gx LESS_TERMCAP_us (printf "\033[01;32m")
EOF

    # Create fish functions
    cat > "$CONFIG_DIR/fish/functions/fish_user_key_bindings.fish" <<'EOF'
function fish_user_key_bindings
    # Use vim bindings and cursors
    fish_default_key_bindings -M insert
    fish_vi_key_bindings --no-erase insert
    
    # Ctrl+f to accept autosuggestion
    bind -M insert \cf forward-char
    
    # Ctrl+e to edit command line in editor
    bind -M insert \ce edit_command_buffer
    
    # Alt+. to insert last argument
    bind -M insert \e. history-token-search-backward
end
EOF
}

# Create Starship configuration
create_starship_config() {
    log "Creating Starship configuration..."
    
    cat > "$CONFIG_DIR/starship.toml" <<'EOF'
format = """
[╭─user───❯](bold blue) $username
[┣─system─❯](bold yellow) $hostname
[┣─project❯](bold red) $directory$rust$git_branch$git_status$package$golang$terraform$docker_context$python$docker_context$nodejs
[╰─cmd────❯](bold green) """

[username]
style_user = "green bold"
style_root = "red bold"
format = "[$user]($style) "
disabled = false
show_always = true

[hostname]
ssh_only = false
format = "[$hostname](bold red) "
disabled = false

[directory]
truncation_length = 3
truncation_symbol = "…/"
home_symbol = " ~"
read_only_style = "197"
read_only = "  "
format = "at [$path]($style)[$read_only]($read_only_style) "

[git_branch]
symbol = " "
format = "on [$symbol$branch]($style) "
truncation_length = 4
truncation_symbol = "…/"
style = "bold green"

[git_status]
format = '[\($all_status$ahead_behind\)]($style) '
style = "bold green"
conflicted = "🏳"
up_to_date = " "
untracked = " "
ahead = "⇡${count}"
diverged = "⇕⇡${ahead_count}⇣${behind_count}"
behind = "⇣${count}"
stashed = " "
modified = " "
staged = '[++\($count\)](green)'
renamed = "襁 "
deleted = " "

[terraform]
format = "via [ terraform $version]($style) 壟 [$workspace]($style) "

[vagrant]
format = "via [ vagrant $version]($style) "

[docker_context]
format = "via [ $context](bold blue) "

[helm]
format = "via [ $version](bold purple) "

[python]
symbol = " "
python_binary = "python3"

[nodejs]
format = "via [🤖 $version](bold green) "

[ruby]
format = "via [ $version]($style) "

[kubernetes]
format = 'on [⛵ $context \($namespace\)](dimmed green) '
disabled = false
[kubernetes.context_aliases]
"dev.local.cluster.k8s" = "dev"
".*/openshift-cluster/.*" = "openshift"
"gke_.*_(?P<cluster>[\\w-]+)" = "gke-$cluster"

[kubernetes.user_aliases]
"dev.local.cluster.k8s" = "dev"
"root/.*" = "root"

[memory_usage]
disabled = false
threshold = -1
symbol = " "
style = "bold dimmed green"
format = "via $symbol [${ram}( | ${swap})]($style) "

[time]
disabled = false
format = '🕙[\[ $time \]]($style) '
time_format = "%T"
utc_time_offset = "local"
time_range = "10:00:00-14:00:00"
EOF
}

# Create useful scripts
create_scripts() {
    log "Creating useful scripts..."
    
    local scripts_dir="$HOME/.local/bin"
    mkdir -p "$scripts_dir"
    
    # Hyprshot wrapper script
    cat > "$scripts_dir/screenshot" <<'EOF'
#!/bin/bash
# Enhanced screenshot script for Hyprland

SCREENSHOT_DIR="$HOME/Pictures/Screenshots"
mkdir -p "$SCREENSHOT_DIR"

case "$1" in
    "area"|"region")
        hyprshot -m region -o "$SCREENSHOT_DIR"
        notify-send "Screenshot" "Area screenshot saved to $SCREENSHOT_DIR"
        ;;
    "window")
        hyprshot -m window -o "$SCREENSHOT_DIR"
        notify-send "Screenshot" "Window screenshot saved to $SCREENSHOT_DIR"
        ;;
    "output"|"screen"|"full")
        hyprshot -m output -o "$SCREENSHOT_DIR"
        notify-send "Screenshot" "Full screen screenshot saved to $SCREENSHOT_DIR"
        ;;
    *)
        echo "Usage: screenshot [area|window|full]"
        echo "  area/region - Select area to screenshot"
        echo "  window      - Screenshot active window"
        echo "  full/screen/output - Screenshot entire screen"
        ;;
esac
EOF

    # Wallpaper management script
    cat > "$scripts_dir/wallpaper" <<'EOF'
#!/bin/bash
# Wallpaper management script for swww

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
CURRENT_WALLPAPER_FILE="$HOME/.cache/current_wallpaper"

# Create wallpaper directory if it doesn't exist
mkdir -p "$WALLPAPER_DIR"

# Function to set wallpaper
set_wallpaper() {
    local wallpaper="$1"
    if [[ -f "$wallpaper" ]]; then
        swww img "$wallpaper" --transition-type wipe --transition-duration 2
        echo "$wallpaper" > "$CURRENT_WALLPAPER_FILE"
        notify-send "Wallpaper" "Changed to $(basename "$wallpaper")"
        return 0
    else
        notify-send "Wallpaper Error" "File not found: $wallpaper"
        return 1
    fi
}

# Function to get random wallpaper
get_random_wallpaper() {
    find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.bmp" \) | shuf -n 1
}

case "$1" in
    "random")
        WALLPAPER=$(get_random_wallpaper)
        if [[ -n "$WALLPAPER" ]]; then
            set_wallpaper "$WALLPAPER"
        else
            notify-send "Wallpaper Error" "No wallpapers found in $WALLPAPER_DIR"
            echo "No wallpapers found. Add images to $WALLPAPER_DIR"
        fi
        ;;
    "current")
        if [[ -f "$CURRENT_WALLPAPER_FILE" ]]; then
            cat "$CURRENT_WALLPAPER_FILE"
        else
            echo "No current wallpaper set"
        fi
        ;;
    "list")
        echo "Available wallpapers in $WALLPAPER_DIR:"
        find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.bmp" \) -exec basename {} \;
        ;;
    "")
        echo "Usage: wallpaper [random|current|list|/path/to/image]"
        echo "  random  - Set random wallpaper from $WALLPAPER_DIR"
        echo "  current - Show current wallpaper path"
        echo "  list    - List available wallpapers"
        echo "  <path>  - Set specific wallpaper"
        ;;
    *)
        if [[ -f "$1" ]]; then
            set_wallpaper "$1"
        elif [[ -f "$WALLPAPER_DIR/$1" ]]; then
            set_wallpaper "$WALLPAPER_DIR/$1"
        else
            echo "File not found: $1"
            echo "Use 'wallpaper list' to see available wallpapers"
        fi
        ;;
esac
EOF

    # System update script
    cat > "$scripts_dir/system-update" <<'EOF'
#!/bin/bash
# Comprehensive system update script

echo "🔄 Starting system update..."

# Update pacman database
echo "📦 Updating package database..."
sudo pacman -Sy

# Update system packages
echo "⬆️  Updating system packages..."
sudo pacman -Su --noconfirm

# Update AUR packages if yay is available
if command -v yay &> /dev/null; then
    echo "🏗️  Updating AUR packages..."
    yay -Su --noconfirm
fi

# Clean package cache
echo "🧹 Cleaning package cache..."
sudo pacman -Sc --noconfirm

# Update fish completions
if command -v fish &> /dev/null; then
    echo "🐟 Updating fish completions..."
    fish -c "fish_update_completions"
fi

# Update starship if available
if command -v starship &> /dev/null; then
    echo "⭐ Updating starship..."
    starship update || echo "Starship update failed or not needed"
fi

echo "✅ System update completed!"
notify-send "System Update" "All packages updated successfully" --icon=software-update-available
EOF

    # Hyprland reload script
    cat > "$scripts_dir/hypr-reload" <<'EOF'
#!/bin/bash
# Hyprland configuration reload script

echo "🔄 Reloading Hyprland configuration..."

# Reload Hyprland
hyprctl reload

# Restart waybar
pkill waybar
sleep 1
waybar &

# Restart dunst
pkill dunst
sleep 1
dunst &

# Restart swww and set wallpaper
pkill swww
sleep 1
swww init
if [[ -f "$HOME/.cache/current_wallpaper" ]]; then
    wallpaper "$(cat "$HOME/.cache/current_wallpaper")"
else
    wallpaper random
fi

notify-send "Hyprland" "Configuration reloaded successfully"
echo "✅ Hyprland configuration reloaded!"
EOF

    # Make all scripts executable
    chmod +x "$scripts_dir"/*
    
    # Add scripts directory to PATH
    if [[ ":$PATH:" != *":$scripts_dir:"* ]]; then
        echo "export PATH=\"$scripts_dir:\$PATH\"" >> "$HOME/.bashrc"
        echo "set -gx PATH $scripts_dir \$PATH" >> "$CONFIG_DIR/fish/config.fish"
    fi
    
    log "Scripts created in $scripts_dir"
}

# Setup wallpapers
setup_wallpapers() {
    log "Setting up wallpapers..."
    
    local wallpaper_dir="$HOME/Pictures/Wallpapers"
    mkdir -p "$wallpaper_dir"
    
    # Create a simple gradient wallpaper as default
    if command -v convert &> /dev/null; then
        convert -size 1920x1080 gradient:#1e1e2e-#89b4fa "$wallpaper_dir/default.jpg"
        log "Created default gradient wallpaper"
    else
        # Download a simple wallpaper if imagemagick is not available
        if command -v curl &> /dev/null; then
            curl -s -o "$wallpaper_dir/default.jpg" "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=1920&h=1080&fit=crop" || {
                warning "Failed to download default wallpaper"
            }
        fi
    fi
    
    log "Wallpaper directory created at $wallpaper_dir"
}

# Setup services and autostart
setup_services() {
    log "Setting up services and autostart..."
    
    # Enable user services
    systemctl --user enable --now pipewire pipewire-pulse wireplumber
    
    # Add user to necessary groups
    sudo usermod -a -G video,audio,input "$USER"
    
    # Create Hyprland desktop entry
    sudo tee /usr/share/wayland-sessions/hyprland.desktop > /dev/null <<EOF
[Desktop Entry]
Name=Hyprland
Comment=An intelligent dynamic tiling Wayland compositor
Exec=Hyprland
Type=Application
EOF
    
    # Create autostart directory and scripts
    mkdir -p "$CONFIG_DIR/autostart"
    
    # Create swww autostart script
    cat > "$CONFIG_DIR/autostart/swww.sh" <<'EOF'
#!/bin/bash
# Start swww daemon and set wallpaper
swww init
sleep 2
if [[ -f "$HOME/.cache/current_wallpaper" ]]; then
    swww img "$(cat "$HOME/.cache/current_wallpaper")"
else
    wallpaper random
fi
EOF
    chmod +x "$CONFIG_DIR/autostart/swww.sh"
}

# Install all dotfiles
install_dotfiles() {
    log "Installing dotfiles..."
    
    # Create all configuration files
    create_hyprland_config
    create_waybar_config
    create_wofi_config
    create_dunst_config
        create_kitty_config
    create_fish_config
    create_starship_config
    create_scripts
    setup_wallpapers
    setup_services
    
    log "All dotfiles installed successfully"
}

# Fix common issues
fix_common_issues() {
    log "Fixing common issues..."
    
    # Fix SDDM Wayland session detection
    if [[ "$INSTALL_SDDM" == "y" ]]; then
        # Ensure Hyprland session is properly registered
        sudo mkdir -p /usr/share/wayland-sessions
        if [[ ! -f /usr/share/wayland-sessions/hyprland.desktop ]]; then
            sudo tee /usr/share/wayland-sessions/hyprland.desktop > /dev/null <<EOF
[Desktop Entry]
Name=Hyprland
Comment=An intelligent dynamic tiling Wayland compositor
Exec=Hyprland
Type=Application
DesktopNames=Hyprland
EOF
        fi
        
        # Fix SDDM permissions
        sudo chown -R sddm:sddm /var/lib/sddm
        
        # Ensure SDDM can access Wayland sessions
        sudo chmod 755 /usr/share/wayland-sessions
        sudo chmod 644 /usr/share/wayland-sessions/*.desktop
    fi
    
    # Fix Waybar not starting
    mkdir -p "$HOME/.config/systemd/user"
    cat > "$HOME/.config/systemd/user/waybar.service" <<EOF
[Unit]
Description=Waybar
After=graphical-session.target
Wants=graphical-session.target
PartOf=graphical-session.target

[Service]
Type=simple
ExecStart=/usr/bin/waybar
Restart=on-failure
RestartSec=1

[Install]
WantedBy=default.target
EOF
    
    # Fix Rofi Wayland
    mkdir -p "$CONFIG_DIR/rofi"
    cat > "$CONFIG_DIR/rofi/config.rasi" <<'EOF'
configuration {
    modi: "drun,run,window";
    show-icons: true;
    terminal: "kitty";
    drun-display-format: "{icon} {name}";
    location: 0;
    disable-history: false;
    hide-scrollbar: true;
    display-drun: "   Apps ";
    display-run: "   Run ";
    display-window: " 﩯  Window";
    display-Network: " 󰤨  Network";
    sidebar-mode: true;
}

@theme "catppuccin-mocha"
EOF

    # Create Rofi theme
    mkdir -p "$CONFIG_DIR/rofi/themes"
    cat > "$CONFIG_DIR/rofi/themes/catppuccin-mocha.rasi" <<'EOF'
* {
    bg-col:  #1e1e2e;
    bg-col-light: #1e1e2e;
    border-col: #89b4fa;
    selected-col: #1e1e2e;
    blue: #89b4fa;
    fg-col: #cdd6f4;
    fg-col2: #f38ba8;
    grey: #6c7086;

    width: 600;
    font: "JetBrainsMono Nerd Font 14";
}

element-text, element-icon , mode-switcher {
    background-color: inherit;
    text-color:       inherit;
}

window {
    height: 360px;
    border: 3px;
    border-color: @border-col;
    background-color: @bg-col;
    border-radius: 15px;
}

mainbox {
    background-color: @bg-col;
}

inputbar {
    children: [prompt,entry];
    background-color: @bg-col;
    border-radius: 5px;
    padding: 2px;
}

prompt {
    background-color: @blue;
    padding: 6px;
    text-color: @bg-col;
    border-radius: 3px;
    margin: 20px 0px 0px 20px;
}

textbox-prompt-colon {
    expand: false;
    str: ":";
}

entry {
    padding: 6px;
    margin: 20px 0px 0px 10px;
    text-color: @fg-col;
    background-color: @bg-col;
}

listview {
    border: 0px 0px 0px;
    padding: 6px 0px 0px;
    margin: 10px 0px 0px 20px;
    columns: 2;
    lines: 5;
    background-color: @bg-col;
}

element {
    padding: 5px;
    background-color: @bg-col;
    text-color: @fg-col;
}

element-icon {
    size: 25px;
}

element selected {
    background-color: @selected-col;
    text-color: @fg-col2;
}

mode-switcher {
    spacing: 0;
}

button {
    padding: 10px;
    background-color: @bg-col-light;
    text-color: @grey;
    vertical-align: 0.5;
    horizontal-align: 0.5;
}

button selected {
    background-color: @bg-col;
    text-color: @blue;
}
EOF

    # Fix Waydroid issues by creating proper configuration
    if [[ "$INSTALL_WAYDROID" == "y" ]]; then
        mkdir -p "$HOME/.config/waydroid"
        cat > "$HOME/.config/waydroid/waydroid.cfg" <<EOF
[waydroid]
session_user=$USER
EOF
        
        # Add waydroid to sudoers for easier management
        echo "$USER ALL=(ALL) NOPASSWD: /usr/bin/waydroid" | sudo tee /etc/sudoers.d/waydroid-$USER
    fi
    
    # Fix XDG portals
    mkdir -p "$CONFIG_DIR/xdg-desktop-portal"
    cat > "$CONFIG_DIR/xdg-desktop-portal/hyprland-portals.conf" <<EOF
[preferred]
default=hyprland;gtk
org.freedesktop.impl.portal.Screenshot=hyprland
org.freedesktop.impl.portal.ScreenCast=hyprland
org.freedesktop.impl.portal.FileChooser=gtk
EOF

    # Fix environment variables for Wayland
    cat > "$HOME/.pam_environment" <<EOF
# Wayland environment variables
XDG_SESSION_TYPE=wayland
XDG_CURRENT_DESKTOP=Hyprland
XDG_SESSION_DESKTOP=Hyprland
QT_QPA_PLATFORM=wayland;xcb
QT_WAYLAND_DISABLE_WINDOWDECORATION=1
GDK_BACKEND=wayland,x11
MOZ_ENABLE_WAYLAND=1
CLUTTER_BACKEND=wayland
SDL_VIDEODRIVER=wayland
_JAVA_AWT_WM_NONREPARENTING=1
EOF

    # Create session script for proper startup
    mkdir -p "$HOME/.local/share/applications"
    cat > "$HOME/.local/share/applications/hyprland-session.desktop" <<EOF
[Desktop Entry]
Name=Hyprland Session
Exec=env XDG_CURRENT_DESKTOP=Hyprland Hyprland
Type=Application
NoDisplay=true
EOF

    log "Common issues fixed"
}

# Post-installation setup
post_install_setup() {
    log "Running post-installation setup..."
    
    # Set Fish as default shell
    if command -v fish &> /dev/null; then
        if [[ "$SHELL" != *"fish"* ]]; then
            echo "Setting Fish as default shell..."
            chsh -s "$(which fish)"
        fi
    fi
    
    # Generate SSH key if it doesn't exist
    if [[ ! -f "$HOME/.ssh/id_rsa" ]] && [[ ! -f "$HOME/.ssh/id_ed25519" ]]; then
        read -p "Generate SSH key? (y/n): " generate_ssh
        if [[ "$generate_ssh" == "y" ]]; then
            ssh-keygen -t ed25519 -C "$USER@$(hostname)" -f "$HOME/.ssh/id_ed25519" -N ""
            log "SSH key generated at ~/.ssh/id_ed25519"
        fi
    fi
    
    # Setup Git configuration
    if command -v git &> /dev/null; then
        if [[ -z "$(git config --global user.name)" ]]; then
            read -p "Enter your Git username: " git_username
            read -p "Enter your Git email: " git_email
            git config --global user.name "$git_username"
            git config --global user.email "$git_email"
            git config --global init.defaultBranch main
            log "Git configuration set"
        fi
    fi
    
    # Create useful directories
    mkdir -p "$HOME/Documents/Projects"
    mkdir -p "$HOME/Downloads/Software"
    mkdir -p "$HOME/Pictures/Screenshots"
    mkdir -p "$HOME/.local/share/applications"
    
    # Set proper permissions
    chmod 700 "$HOME/.ssh" 2>/dev/null || true
    chmod 600 "$HOME/.ssh/"* 2>/dev/null || true
    
    log "Post-installation setup completed"
}

# Create uninstall script
create_uninstall_script() {
    log "Creating uninstall script..."
    
    cat > "$HOME/uninstall-hyprland.sh" <<'EOF'
#!/bin/bash
# Hyprland Uninstall Script

echo "⚠️  This will remove Hyprland and all related configurations!"
read -p "Are you sure you want to continue? (y/N): " confirm

if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "Uninstall cancelled."
    exit 0
fi

echo "🗑️  Removing Hyprland and related packages..."

# Stop services
sudo systemctl disable sddm.service 2>/dev/null || true
systemctl --user stop waybar.service 2>/dev/null || true
systemctl --user disable waybar.service 2>/dev/null || true

# Remove packages
packages_to_remove=(
    "hyprland"
    "waybar"
    "wofi"
    "rofi-wayland"
    "dunst"
    "swww"
    "sddm"
    "kitty"
    "fish"
    "starship"
)

for package in "${packages_to_remove[@]}"; do
    if pacman -Qs "$package" &> /dev/null; then
        sudo pacman -R --noconfirm "$package" 2>/dev/null || true
    fi
done

# Remove AUR packages
aur_packages=(
    "hyprpicker"
    "wlogout"
    "swaylock-effects"
    "wlsunset"
    "nwg-look"
    "bibata-cursor-theme"
    "hyprshot"
    "waybar-hyprland-git"
    "sddm-sugar-candy-git"
)

for package in "${aur_packages[@]}"; do
    if pacman -Qs "$package" &> /dev/null; then
        yay -R --noconfirm "$package" 2>/dev/null || true
    fi
done

# Remove configuration directories
echo "🗑️  Removing configuration files..."
rm -rf ~/.config/hypr
rm -rf ~/.config/waybar
rm -rf ~/.config/wofi
rm -rf ~/.config/rofi
rm -rf ~/.config/dunst
rm -rf ~/.config/kitty
rm -rf ~/.config/fish
rm -rf ~/.config/starship.toml
rm -rf ~/.config/autostart
rm -rf ~/.config/systemd/user/waybar.service
rm -rf ~/.config/xdg-desktop-portal

# Remove scripts
rm -rf ~/.local/bin/screenshot
rm -rf ~/.local/bin/wallpaper
rm -rf ~/.local/bin/system-update
rm -rf ~/.local/bin/hypr-reload

# Remove environment files
rm -f ~/.pam_environment

# Remove desktop entries
rm -f ~/.local/share/applications/hyprland-session.desktop
sudo rm -f /usr/share/wayland-sessions/hyprland.desktop

# Remove SDDM configuration
sudo rm -f /etc/sddm.conf.d/10-wayland.conf

# Remove NVIDIA configuration (if exists)
sudo rm -f /etc/modprobe.d/nvidia.conf
sudo rm -f /etc/udev/rules.d/61-gdm.rules

# Remove sudoers entry for waydroid
sudo rm -f /etc/sudoers.d/waydroid-*

echo "✅ Hyprland uninstalled successfully!"
echo "💡 You may want to:"
echo "   - Reboot your system"
echo "   - Install another desktop environment"
echo "   - Change your default shell back to bash: chsh -s /bin/bash"
EOF

    chmod +x "$HOME/uninstall-hyprland.sh"
    log "Uninstall script created at ~/uninstall-hyprland.sh"
}

# Main installation function
main() {
    log "Starting Enhanced Hyprland Installation"
    
    # Check prerequisites
    check_arch
    
    # Get user preferences
    ask_user_preferences
    
    # Installation steps
    install_base_packages
    install_aur_packages
    install_nvidia_drivers
    install_display_manager
    install_waydroid_support
    install_dotfiles
    fix_common_issues
    post_install_setup
    create_uninstall_script
    
    # Final message
    echo -e "\n${GREEN}🎉 Hyprland installation completed successfully!${NC}\n"
    echo -e "${BLUE}📋 Installation Summary:${NC}"
    echo -e "   • Hyprland with optimized configuration"
    echo -e "   • Waybar status bar with custom theme"
    echo -e "   • Wofi and Rofi application launchers"
    echo -e "   • Dunst notification daemon"
    echo -e "   • Kitty terminal with Catppuccin theme"
    echo -e "   • Fish shell with Starship prompt"
    echo -e "   • Custom scripts and utilities"
    [[ "$INSTALL_SDDM" == "y" ]] && echo -e "   • SDDM display manager configured"
    [[ "$INSTALL_NVIDIA" == "y" ]] && echo -e "   • NVIDIA drivers for Wayland"
    [[ "$INSTALL_WAYDROID" == "y" ]] && echo -e "   • Waydroid Android emulation"
    
    echo -e "\n${YELLOW}📝 Next Steps:${NC}"
    echo -e "   1. Reboot your system: ${GREEN}sudo reboot${NC}"
    [[ "$INSTALL_SDDM" == "y" ]] && echo -e "   2. Select Hyprland from SDDM login screen"
    echo -e "   3. Add wallpapers to ~/Pictures/Wallpapers/"
    echo -e "   4. Customize configurations in ~/.config/"
    echo -e "   5. Run 'wallpaper random' to set a wallpaper"
    
    echo -e "\n${BLUE}🔧 Useful Commands:${NC}"
    echo -e "   • ${GREEN}Super + Q${NC} - Open terminal"
    echo -e "   • ${GREEN}Super + R${NC}
    echo -e "   • ${GREEN}Super + R${NC} - Open application launcher"
    echo -e "   • ${GREEN}Super + C${NC} - Close window"
    echo -e "   • ${GREEN}Super + M${NC} - Exit Hyprland"
    echo -e "   • ${GREEN}Super + V${NC} - Toggle floating"
    echo -e "   • ${GREEN}Super + J${NC} - Toggle layout"
    echo -e "   • ${GREEN}Super + P${NC} - Toggle pseudo"
    echo -e "   • ${GREEN}Super + 1-9${NC} - Switch workspaces"
    echo -e "   • ${GREEN}Super + Shift + 1-9${NC} - Move window to workspace"
    echo -e "   • ${GREEN}Print${NC} - Screenshot"
    echo -e "   • ${GREEN}Super + L${NC} - Lock screen"
    
    echo -e "\n${BLUE}🛠️  Useful Scripts:${NC}"
    echo -e "   • ${GREEN}screenshot [area|window|full]${NC} - Take screenshots"
    echo -e "   • ${GREEN}wallpaper [random|current|list]${NC} - Manage wallpapers"
    echo -e "   • ${GREEN}system-update${NC} - Update system and AUR packages"
    echo -e "   • ${GREEN}hypr-reload${NC} - Reload Hyprland configuration"
    
    echo -e "\n${BLUE}📁 Important Directories:${NC}"
    echo -e "   • ${GREEN}~/.config/hypr/${NC} - Hyprland configuration"
    echo -e "   • ${GREEN}~/.config/waybar/${NC} - Status bar configuration"
    echo -e "   • ${GREEN}~/.config/kitty/${NC} - Terminal configuration"
    echo -e "   • ${GREEN}~/Pictures/Wallpapers/${NC} - Wallpaper directory"
    echo -e "   • ${GREEN}~/Pictures/Screenshots/${NC} - Screenshot directory"
    
    echo -e "\n${YELLOW}⚠️  Troubleshooting:${NC}"
    echo -e "   • If Waybar doesn't start: ${GREEN}waybar &${NC}"
    echo -e "   • If wallpaper doesn't load: ${GREEN}wallpaper random${NC}"
    echo -e "   • For NVIDIA issues: Check ~/.config/hypr/hyprland.conf"
    echo -e "   • To uninstall: ${GREEN}~/uninstall-hyprland.sh${NC}"
    
    echo -e "\n${BLUE}🔗 Resources:${NC}"
    echo -e "   • Hyprland Wiki: https://wiki.hyprland.org/"
    echo -e "   • Configuration: https://wiki.hyprland.org/Configuring/Configuring-Hyprland/"
    echo -e "   • Waybar: https://github.com/Alexays/Waybar/wiki"
    
    if [[ "$INSTALL_SDDM" == "y" ]]; then
        echo -e "\n${GREEN}🔄 Please reboot to use SDDM and Hyprland${NC}"
        read -p "Reboot now? (y/n): " reboot_now
        if [[ "$reboot_now" == "y" ]]; then
            sudo reboot
        fi
    else
        echo -e "\n${GREEN}🚀 You can start Hyprland by running: ${YELLOW}Hyprland${NC}"
    fi
}

# Error handling
set -eE
trap 'error "Script failed at line $LINENO. Command: $BASH_COMMAND"' ERR

# Script execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
