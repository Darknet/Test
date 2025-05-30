#!/bin/bash

# Enhanced Hyprland Installation Script for Arch Linux
# Version: 2.0
# Author: Enhanced by AI Assistant
# Description: Complete Hyprland desktop environment setup

# Script information
SCRIPT_NAME="Enhanced Hyprland Installer"
SCRIPT_VERSION="2.0"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Global variables
CONFIG_DIR="$HOME/.config"
INSTALL_NVIDIA=""
INSTALL_SDDM=""
INSTALL_WAYDROID=""
INSTALL_GAMING=""
INSTALL_DEV_TOOLS=""

# Logging functions
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
    exit 1
}

# Check if running on Arch Linux
check_arch() {
    if [[ ! -f /etc/arch-release ]]; then
        error "This script is designed for Arch Linux only!"
    fi
    
    if [[ $EUID -eq 0 ]]; then
        error "Don't run this script as root!"
    fi
    
    log "Arch Linux detected. Proceeding with installation..."
}

# Ask user preferences
ask_user_preferences() {
    echo -e "${BLUE}🔧 Installation Configuration${NC}"
    echo "Please answer the following questions to customize your installation:"
    echo
    
    read -p "Install NVIDIA drivers? (y/n): " INSTALL_NVIDIA
    read -p "Install SDDM display manager? (y/n): " INSTALL_SDDM
    read -p "Install Waydroid (Android support)? (y/n): " INSTALL_WAYDROID
    read -p "Install gaming tools (Steam, Lutris)? (y/n): " INSTALL_GAMING
    read -p "Install development tools (VS Code, Docker)? (y/n): " INSTALL_DEV_TOOLS
    
    echo
    log "Configuration saved. Starting installation..."
}

# Install base packages
install_base_packages() {
    log "Installing base packages..."
    
    # Update system
    sudo pacman -Syu --noconfirm
    
    # Install yay if not present
    if ! command -v yay &> /dev/null; then
        log "Installing yay AUR helper..."
        sudo pacman -S --needed --noconfirm base-devel git
        cd /tmp
        git clone https://aur.archlinux.org/yay.git
        cd yay
        makepkg -si --noconfirm
        cd ~
    fi
    
    # Core packages
    local packages=(
        # Hyprland and Wayland
        "hyprland"
        "xdg-desktop-portal-hyprland"
        "xdg-desktop-portal-gtk"
        "qt5-wayland"
        "qt6-wayland"
        
        # Audio
        "pipewire"
        "pipewire-alsa"
        "pipewire-pulse"
        "pipewire-jack"
        "wireplumber"
        "pamixer"
        "pavucontrol"
        
        # Fonts
        "ttf-jetbrains-mono-nerd"
        "ttf-font-awesome"
        "noto-fonts"
        "noto-fonts-emoji"
        
        # System utilities
        "waybar"
        "wofi"
        "dunst"
        "swww"
        "kitty"
        "fish"
        "starship"
        "brightnessctl"
        "grim"
        "slurp"
        "wl-clipboard"
        "cliphist"
        "polkit-gnome"
        
        # File management
        "thunar"
        "thunar-volman"
        "thunar-archive-plugin"
        "file-roller"
        
        # Network
        "networkmanager"
        "network-manager-applet"
        
        # Themes and appearance
        "gtk3"
        "gtk4"
        "gnome-themes-extra"
        "papirus-icon-theme"
        
        # Basic applications
        "firefox"
        "mpv"
        "imv"
        "btop"
        "neofetch"
    )
    
    for package in "${packages[@]}"; do
        if ! pacman -Qs "$package" &> /dev/null; then
            log "Installing $package..."
            sudo pacman -S --noconfirm "$package" || warning "Failed to install $package"
        fi
    done
    
    # Enable NetworkManager
    sudo systemctl enable NetworkManager
}

# Install AUR packages
install_aur_packages() {
    log "Installing AUR packages..."
    
    local aur_packages=(
        "rofi-wayland"
        "swaylock-effects"
        "wlogout"
        "hyprpicker"
        "hyprshot"
        "wlsunset"
        "nwg-look"
        "bibata-cursor-theme"
    )
    
    for package in "${aur_packages[@]}"; do
        if ! pacman -Qs "$package" &> /dev/null; then
            log "Installing $package from AUR..."
            yay -S --noconfirm "$package" || warning "Failed to install $package"
        fi
    done
}

# Install NVIDIA drivers
install_nvidia_drivers() {
    if [[ "$INSTALL_NVIDIA" != "y" ]]; then
        return
    fi
    
    log "Installing NVIDIA drivers for Wayland..."
    
    # Detect NVIDIA GPU
    if lspci | grep -i nvidia &> /dev/null; then
        sudo pacman -S --noconfirm nvidia nvidia-utils nvidia-settings
        
        # Configure NVIDIA for Wayland
        sudo tee /etc/modprobe.d/nvidia.conf > /dev/null <<EOF
options nvidia-drm modeset=1
options nvidia NVreg_PreserveVideoMemoryAllocations=1
EOF
        
        # Add to initramfs
        sudo sed -i 's/MODULES=()/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf
        sudo mkinitcpio -P
        
        log "NVIDIA drivers installed and configured"
    else
        warning "No NVIDIA GPU detected, skipping NVIDIA driver installation"
    fi
}

# Install display manager
install_display_manager() {
    if [[ "$INSTALL_SDDM" != "y" ]]; then
        return
    fi
    
    log "Installing and configuring SDDM..."
    
    sudo pacman -S --noconfirm sddm
    
    # Configure SDDM for Wayland
    sudo mkdir -p /etc/sddm.conf.d
    sudo tee /etc/sddm.conf.d/10-wayland.conf > /dev/null <<EOF
[General]
DisplayServer=wayland
GreeterEnvironment=QT_WAYLAND_SHELL_INTEGRATION=layer-shell

[Wayland]
SessionDir=/usr/share/wayland-sessions
EOF
    
    sudo systemctl enable sddm
    log "SDDM configured and enabled"
}

# Install Waydroid support
install_waydroid_support() {
    if [[ "$INSTALL_WAYDROID" != "y" ]]; then
        return
    fi
    
    log "Installing Waydroid..."
    yay -S --noconfirm waydroid
    log "Waydroid installed. Run 'sudo waydroid init' after reboot to set up"
}

# Create Hyprland configuration
create_hyprland_config() {
    log "Creating Hyprland configuration..."
    
    mkdir -p "$CONFIG_DIR/hypr"
    
    cat > "$CONFIG_DIR/hypr/hyprland.conf" <<'EOF'
# Hyprland Configuration
# See https://wiki.hyprland.org/Configuring/Configuring-Hyprland/

# Monitor configuration
monitor=,preferred,auto,auto

# Environment variables
env = XCURSOR_SIZE,24
env = QT_QPA_PLATFORM,wayland
env = XDG_CURRENT_DESKTOP,Hyprland
env = XDG_SESSION_TYPE,wayland
env = XDG_SESSION_DESKTOP,Hyprland

# NVIDIA specific (uncomment if using NVIDIA)
# env = LIBVA_DRIVER_NAME,nvidia
# env = __GLX_VENDOR_LIBRARY_NAME,nvidia
# env = WLR_NO_HARDWARE_CURSORS,1

# Autostart
exec-once = waybar
exec-once = dunst
exec-once = swww init
exec-once = /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1
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
    sensitivity = 0
    
    touchpad {
        natural_scroll = false
    }
}

# General settings
general {
    gaps_in = 5
    gaps_out = 10
    border_size = 2
    col.active_border = rgba(89b4faee) rgba(cba6f7ee) 45deg
    col.inactive_border = rgba(585b70aa)
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
        vibrancy = 0.1696
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
windowrule = float, ^(nm-applet)$
windowrule = float, ^(thunar)$
windowrule = float, ^(nwg-look)$

# Key bindings
$mainMod = SUPER

# Applications
bind = $mainMod, Q, exec, kitty
bind = $mainMod, C, killactive,
bind = $mainMod, M, exit,
bind = $mainMod, E, exec, thunar
bind = $mainMod, V, togglefloating,
bind = $mainMod, R, exec, wofi --show drun
bind = $mainMod SHIFT, R, exec, rofi -show run
bind = $mainMod, P, pseudo,
bind = $mainMod, J, togglesplit,
bind = $mainMod, F, fullscreen,
bind = $mainMod, L, exec, swaylock

# Screenshots
bind = , Print, exec, hyprshot -m output
bind = $mainMod, Print, exec, hyprshot -m window
bind = $mainMod SHIFT, Print, exec, hyprshot -m region

# Audio
bind = , XF86AudioRaiseVolume, exec, pamixer -i 5
bind = , XF86AudioLowerVolume, exec, pamixer -d 5
bind = , XF86AudioMute, exec, pamixer -t

# Brightness
bind = , XF86MonBrightnessUp, exec, brightnessctl set 5%+
bind = , XF86MonBrightnessDown, exec, brightnessctl set 5%-

# Move focus
bind = $mainMod, left, movefocus, l
bind = $mainMod, right, movefocus, r
bind = $mainMod, up, movefocus, u
bind = $mainMod, down, movefocus, d

# Switch workspaces
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

# Move active window to workspace
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

# Special workspace
bind = $mainMod, S, togglespecialworkspace, magic
bind = $mainMod SHIFT, S, movetoworkspace, special:magic

# Scroll through workspaces
bind = $mainMod, mouse_down, workspace, e+1
bind = $mainMod, mouse_up, workspace, e-1

# Move/resize windows
bindm = $mainMod, mouse:272, movewindow
bindm = $mainMod, mouse:273, resizewindow

# Clipboard
bind = $mainMod, V, exec, cliphist list | wofi --dmenu | cliphist decode | wl-copy
EOF
}

# Create Waybar configuration
create_waybar_config() {
    log "Creating Waybar configuration..."
    
    mkdir -p "$CONFIG_DIR/waybar"
    
    cat > "$CONFIG_DIR/waybar/config.jsonc" <<'EOF'
{
    "layer": "top",
    "position": "top",
    "height": 30,
    "spacing": 4,
    "modules-left": ["hyprland/workspaces", "hyprland/mode", "hyprland/scratchpad"],
    "modules-center": ["hyprland/window"],
    "modules-right": ["idle_inhibitor", "pulseaudio", "network", "cpu", "memory", "temperature", "backlight", "battery", "clock", "tray"],
    
    "hyprland/workspaces": {
        "disable-scroll": true,
        "all-outputs": true,
        "format": "{icon}",
        "format-icons": {
            "1": "",
            "2": "",
            "3": "",
            "4": "",
            "5": "",
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
        "max-length": 50
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
        "format-alt": "{:%Y-%m-%d}"
    },
    
    "cpu": {
        "format": "{usage}% ",
        "tooltip": false
    },
    
    "memory": {
        "format": "{}% "
    },
    
    "temperature": {
        "critical-threshold": 80,
        "format": "{temperatureC}°C {icon}",
        "format-icons": ["", "", ""]
    },
    
    "backlight": {
        "format": "{percent}% {icon}",
        "format-icons": ["", "", "", "", "", "", "", "", ""]
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
        "format-alt": "{ifname}: {ipaddr}/{cidr}"
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
        "on-click": "pavucontrol"
    }
}
EOF

    cat > "$CONFIG_DIR/waybar/style.css" <<'EOF'
* {
    border: none;
    border-radius: 0;
    font-family: "JetBrainsMono Nerd Font";
    font-weight: bold;
    font-size: 14px;
    min-height: 0;
}

window#waybar {
    background: rgba(30, 30, 46, 0.9);
    border-bottom: 3px solid rgba(137, 180, 250, 0.8);
    color: #cdd6f4;
    transition-property: background-color;
    transition-duration: .5s;
}

window#waybar.hidden {
    opacity: 0.2;
}

button {
    box-shadow: inset 0 -3px transparent;
    border: none;
    border-radius: 0;
}

button:hover {
    background: inherit;
    box-shadow: inset 0 -3px #cdd6f4;
}

#workspaces button {
    padding: 0 5px;
    background-color: transparent;
    color: #cdd6f4;
}

#workspaces button:hover {
    background: rgba(0, 0, 0, 0.2);
}

#workspaces button.focused {
    background-color: #89b4fa;
    box-shadow: inset 0 -3px #cdd6f4;
}

#workspaces button.urgent {
    background-color: #f38ba8;
}

#mode {
    background-color: #f9e2af;
    color: #1e1e2e;
    border-bottom: 3px solid #cdd6f4;
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
}

#battery {
    background-color: #a6e3a1;
    color: #1e1e2e;
}

#battery.charging, #battery.plugged {
    color: #1e1e2e;
    background-color: #a6e3a1;
}

@keyframes blink {
    to {
        background-color: #f38ba8;
        color: #1e1e2e;
    }
}

#battery.critical:not(.charging) {
    background-color: #f38ba8;
    color: #cdd6f4;
    animation-name: blink;
    animation-duration: 0.5s;
    animation-timing-function: linear;
    animation-iteration-count: infinite;
    animation-direction: alternate;
}

label:focus {
    background-color: #1e1e2e;
}

#cpu {
    background-color: #fab387;
    color: #1e1e2e;
}

#memory {
    background-color: #cba6f7;
    color: #1e1e2e;
}

#disk {
    background-color: #f9e2af;
    color: #1e1e2e;
}

#backlight {
    background-color: #f9e2af;
    color: #1e1e2e;
}

#network {
    background-color: #94e2d5;
    color: #1e1e2e;
}

#network.disconnected {
    background-color: #f38ba8;
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
    background-color: #f38ba8;
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
    background-color: #cdd6f4;
    color: #1e1e2e;
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
prompt=Search...
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
EOF

    cat > "$CONFIG_DIR/wofi/style.css" <<'EOF'
window {
    margin: 0px;
    border: 2px solid #89b4fa;
    background-color: #1e1e2e;
    border-radius: 15px;
}

#input {
    margin: 5px;
    border: none;
    color: #cdd6f4;
    background-color: #313244;
    border-radius: 10px;
    padding: 10px;
    font-size: 14px;
}

#inner-box {
    margin: 5px;
    border: none;
    background-color: #1e1e2e;
    border-radius: 10px;
}

#outer-box {
    margin: 5px;
    border: none;
    background-color: #1e1e2e;
    border-radius: 10px;
}

#scroll {
    margin: 0px;
    border: none;
}

#text {
    margin: 5px;
    border: none;
    color: #cdd6f4;
    font-size: 14px;
}

#entry {
    border-radius: 10px;
    margin: 2px;
    padding: 5px;
}

#entry:selected {
    background-color: #89b4fa;
    color: #1e1e2e;
}

#text:selected {
    color: #1e1e2e;
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
    width = 300
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
    transparency = 0
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
    min_icon_size = 0
    max_icon_size = 32
    icon_path = /usr/share/icons/Papirus/16x16/status/:/usr/share/icons/Papirus/16x16/devices/
    
    sticky_history = yes
    history_length = 20
    
    dmenu = /usr/bin/wofi -p dunst:
    browser = /usr/bin/firefox -new-tab
    
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
    timeout = 10

[urgency_normal]
    background = "#1e1e2e"
    foreground = "#cdd6f4"
    timeout = 10

[urgency_critical]
    background = "#1e1e2e"
    foreground = "#cdd6f4"
    frame_color = "#f38ba8"
    timeout = 0
EOF
}

# Create Kitty configuration
create_kitty_config() {
    log "Creating Kitty configuration..."
    
    mkdir -p "$CONFIG_DIR/kitty"
    
    cat > "$CONFIG_DIR/kitty/kitty.conf" <<'EOF'
# Catppuccin Mocha Theme
include current-theme.conf

# Font configuration
font_family      JetBrainsMono Nerd Font
bold_font        auto
italic_font      auto
bold_italic_font auto
font_size 12.0

# Cursor
cursor_shape block
cursor_blink_interval 0

# Scrollback
scrollback_lines 10000

# Mouse
copy_on_select yes
strip_trailing_spaces smart

# Window layout
remember_window_size  yes
initial_window_width  640
initial_window_height 400
window_padding_width 10
window_margin_width 0

# Tab bar
tab_bar_edge bottom
tab_bar_style powerline
tab_powerline_style slanted
tab_title_template {title}{' :{}:'.format(num_windows) if num_windows > 1 else ''}

# Advanced
shell fish
editor nvim
close_on_child_death no
allow_remote_control yes
term xterm-kitty

# OS specific
wayland_titlebar_color system
linux_display_server wayland

# Key bindings
map ctrl+shift+c copy_to_clipboard
map ctrl+shift+v paste_from_clipboard
map ctrl+shift+t new_tab
map ctrl+shift+q close_tab
map ctrl+shift+right next_tab
map ctrl+shift+left previous
map ctrl+shift+enter new_window
map ctrl+shift+w close_window
map ctrl+shift+] next_window
map ctrl+shift+[ previous_window
map ctrl+shift+f toggle_fullscreen
map ctrl+shift+u scroll_page_up
map ctrl+shift+d scroll_page_down
map ctrl+shift+home scroll_home
map ctrl+shift+end scroll_end
map ctrl+shift+equal increase_font_size
map ctrl+shift+minus decrease_font_size
map ctrl+shift+backspace restore_font_size
EOF

    cat > "$CONFIG_DIR/kitty/current-theme.conf" <<'EOF'
# Catppuccin Mocha
foreground              #CDD6F4
background              #1E1E2E
selection_foreground    #1E1E2E
selection_background    #F5E0DC

# Cursor colors
cursor                  #F5E0DC
cursor_text_color       #1E1E2E

# URL underline color when hovering with mouse
url_color               #F5E0DC

# Kitty window border colors
active_border_color     #B4BEFE
inactive_border_color   #6C7086
bell_border_color       #F9E2AF

# OS Window titlebar colors
wayland_titlebar_color system
macos_titlebar_color system

# Tab bar colors
active_tab_foreground   #11111B
active_tab_background   #CBA6F7
inactive_tab_foreground #CDD6F4
inactive_tab_background #181825
tab_bar_background      #11111B

# Colors for marks (marked text in the terminal)
mark1_foreground #1E1E2E
mark1_background #B4BEFE
mark2_foreground #1E1E2E
mark2_background #CBA6F7
mark3_foreground #1E1E2E
mark3_background #74C7EC

# The 16 terminal colors

# black
color0 #45475A
color8 #585B70

# red
color1 #F38BA8
color9 #F38BA8

# green
color2  #A6E3A1
color10 #A6E3A1

# yellow
color3  #F9E2AF
color11 #F9E2AF

# blue
color4  #89B4FA
color12 #89B4FA

# magenta
color5  #F5C2E7
color13 #F5C2E7

# cyan
color6  #94E2D5
color14 #94E2D5

# white
color7  #BAC2DE
color15 #A6ADC8
EOF
}

# Create Fish shell configuration
create_fish_config() {
    log "Creating Fish shell configuration..."
    
    mkdir -p "$CONFIG_DIR/fish"
    
    cat > "$CONFIG_DIR/fish/config.fish" <<'EOF'
# Fish Shell Configuration

# Disable greeting
set fish_greeting

# Starship prompt
starship init fish | source

# Environment variables
set -gx EDITOR nvim
set -gx BROWSER firefox
set -gx TERMINAL kitty

# Aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias cls='clear'
alias h='history'
alias j='jobs -l'
alias vi='nvim'
alias vim='nvim'

# Git aliases
alias g='git'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias gs='git status'
alias gd='git diff'
alias gb='git branch'
alias gco='git checkout'

# System aliases
alias update='sudo pacman -Syu'
alias install='sudo pacman -S'
alias search='pacman -Ss'
alias remove='sudo pacman -R'
alias autoremove='sudo pacman -Rns (pacman -Qtdq)'

# Hyprland specific
alias hypr-reload='hyprctl reload'
alias hypr-kill='hyprctl kill'

# Custom functions
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

# Add local bin to PATH
if test -d ~/.local/bin
    set -gx PATH ~/.local/bin $PATH
end

# Add cargo bin to PATH
if test -d ~/.cargo/bin
    set -gx PATH ~/.cargo/bin $PATH
end
EOF
}

# Create Starship configuration
create_starship_config() {
    log "Creating Starship configuration..."
    
    cat > "$CONFIG_DIR/starship.toml" <<'EOF'
# Starship Configuration

format = """
[](#89b4fa)\
$os\
$username\
[](bg:#cba6f7 fg:#89b4fa)\
$directory\
[](fg:#cba6f7 bg:#f38ba8)\
$git_branch\
$git_status\
[](fg:#f38ba8 bg:#fab387)\
$c\
$elixir\
$elm\
$golang\
$gradle\
$haskell\
$java\
$julia\
$nodejs\
$nim\
$rust\
$scala\
[](fg:#fab387 bg:#a6e3a1)\
$docker_context\
[](fg:#a6e3a1 bg:#94e2d5)\
$time\
[ ](fg:#94e2d5)\
"""

# Disable the blank line at the start of the prompt
add_newline = false

# You can also replace your username with a neat symbol like   or disable this
# and use the os module below
[username]
show_always = true
style_user = "bg:#89b4fa"
style_root = "bg:#89b4fa"
format = '[$user ]($style)'
disabled = false

# An alternative to the username module which displays a symbol that
# represents the current operating system
[os]
style = "bg:#89b4fa"
disabled = true # Disabled by default

[directory]
style = "bg:#cba6f7"
format = "[ $path ]($style)"
truncation_length = 3
truncation_symbol = "…/"

# Here is how you can shorten some long paths by text replacement
# similar to mapped_locations in Oh My Posh:
[directory.substitutions]
"Documents" = "󰈙 "
"Downloads" = " "
"Music" = " "
"Pictures" = " "

[c]
symbol = " "
style = "bg:#fab387"
format = '[ $symbol ($version) ]($style)'

[docker_context]
symbol = " "
style = "bg:#a6e3a1"
format = '[ $symbol $context ]($style) $path'

[elixir]
symbol = " "
style = "bg:#fab387"
format = '[ $symbol ($version) ]($style)'

[elm]
symbol = " "
style = "bg:#fab387"
format = '[ $symbol ($version) ]($style)'

[git_branch]
symbol = ""
style = "bg:#f38ba8"
format = '[ $symbol $branch ]($style)'

[git_status]
style = "bg:#f38ba8"
format = '[$all_status$ahead_behind ]($style)'

[golang]
symbol = " "
style = "bg:#fab387"
format = '[ $symbol ($version) ]($style)'

[gradle]
style = "bg:#fab387"
format = '[ $symbol ($version) ]($style)'

[haskell]
symbol = " "
style = "bg:#fab387"
format = '[ $symbol ($version) ]($style)'

[java]
symbol = " "
style = "bg:#fab387"
format = '[ $symbol ($version) ]($style)'

[julia]
symbol = " "
style = "bg:#fab387"
format = '[ $symbol ($version) ]($style)'

[nodejs]
symbol = ""
style = "bg:#fab387"
format = '[ $symbol ($version) ]($style)'

[nim]
symbol = "󰆥 "
style = "bg:#fab387"
format = '[ $symbol ($version) ]($style)'

[rust]
symbol = ""
style = "bg:#fab387"
format = '[ $symbol ($version) ]($style)'

[scala]
symbol = " "
style = "bg:#fab387"
format = '[ $symbol ($version) ]($style)'

[time]
disabled = false
time_format = "%R" # Hour:Minute Format
style = "bg:#94e2d5"
format = '[ ♥ $time ]($style)'
EOF
}

# Create useful scripts
create_scripts() {
    log "Creating useful scripts..."
    
    mkdir -p "$HOME/.local/bin"
    
    # Screenshot script
    cat > "$HOME/.local/bin/screenshot" <<'EOF'
#!/bin/bash

case $1 in
    area)
        hyprshot -m region
        ;;
    window)
        hyprshot -m window
        ;;
    full|"")
        hyprshot -m output
        ;;
    *)
        echo "Usage: screenshot [area|window|full]"
        ;;
esac
EOF

    # Wallpaper script
    cat > "$HOME/.local/bin/wallpaper" <<'EOF'
#!/bin/bash

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
mkdir -p "$WALLPAPER_DIR"

case $1 in
    random)
        if [ -d "$WALLPAPER_DIR" ] && [ "$(ls -A $WALLPAPER_DIR)" ]; then
            WALLPAPER=$(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) | shuf -n 1)
            swww img "$WALLPAPER" --transition-type wipe --transition-duration 2
            echo "Set wallpaper: $(basename "$WALLPAPER")"
        else
            echo "No wallpapers found in $WALLPAPER_DIR"
        fi
        ;;
    current)
        echo "Current wallpaper info:"
        swww query
        ;;
    list)
        echo "Available wallpapers:"
        find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) -exec basename {} \;
        ;;
    *)
        if [ -f "$1" ]; then
            swww img "$1" --transition-type wipe --transition-duration 2
            echo "Set wallpaper: $(basename "$1")"
        else
            echo "Usage: wallpaper [random|current|list|/path/to/image]"
        fi
        ;;
esac
EOF

    # System update script
    cat > "$HOME/.local/bin/system-update" <<'EOF'
#!/bin/bash

echo "Updating system packages..."
sudo pacman -Syu

echo "Updating AUR packages..."
yay -Sua

echo "Cleaning package cache..."
sudo pacman -Sc --noconfirm

echo "System update completed!"
EOF

    # Hyprland reload script
    cat > "$HOME/.local/bin/hypr-reload" <<'EOF'
#!/bin/bash

echo "Reloading Hyprland configuration..."
hyprctl reload

echo "Restarting Waybar..."
pkill waybar
waybar &

echo "Hyprland configuration reloaded!"
EOF

    # Make scripts executable
    chmod +x "$HOME/.local/bin/"*
    
    log "Scripts created in ~/.local/bin/"
}

# Install dotfiles and configurations
install_dotfiles() {
    log "Installing dotfiles and configurations..."
    
    # Create necessary directories
    mkdir -p "$HOME/Pictures/"{Wallpapers,Screenshots}
    mkdir -p "$HOME/.local/bin"
    
    # Create configurations
    create_hyprland_config
    create_waybar_config
    create_wofi_config
    create_dunst_config
    create_kitty_config
    create_fish_config
    create_starship_config
    create_scripts
    
    # Set Fish as default shell
    if command -v fish &> /dev/null; then
        if [[ "$SHELL" != *"fish"* ]]; then
            log "Setting Fish as default shell..."
            chsh -s $(which fish)
        fi
    fi
    
    # Configure GTK theme
    mkdir -p "$CONFIG_DIR/gtk-3.0"
    cat > "$CONFIG_DIR/gtk-3.0/settings.ini" <<'EOF'
[Settings]
gtk-theme-name=Adwaita-dark
gtk-icon-theme-name=Papirus-Dark
gtk-font-name=Sans 11
gtk-cursor-theme-name=Bibata-Modern-Classic
gtk-cursor-theme-size=24
gtk-toolbar-style=GTK_TOOLBAR_BOTH
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=1
gtk-menu-images=1
gtk-enable-event-sounds=1
gtk-enable-input-feedback-sounds=1
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintfull
gtk-xft-rgba=rgb
EOF

    mkdir -p "$CONFIG_DIR/gtk-4.0"
    cat > "$CONFIG_DIR/gtk-4.0/settings.ini" <<'EOF'
[Settings]
gtk-theme-name=Adwaita-dark
gtk-icon-theme-name=Papirus-Dark
gtk-font-name=Sans 11
gtk-cursor-theme-name=Bibata-Modern-Classic
gtk-cursor-theme-size=24
gtk-application-prefer-dark-theme=1
EOF
}

# Install gaming tools
install_gaming_tools() {
    if [[ "$INSTALL_GAMING" != "y" ]]; then
        return
    fi
    
    log "Installing gaming tools..."
    
    # Enable multilib repository
    sudo sed -i '/\[multilib\]/,/Include/s/^#//' /etc/pacman.conf
    sudo pacman -Sy
    
    local gaming_packages=(
        "steam"
        "lutris"
        "gamemode"
        "lib32-gamemode"
        "mangohud"
        "lib32-mangohu
        "lib32-mangohud"
        "wine"
        "winetricks"
        "lib32-vulkan-icd-loader"
        "vulkan-tools"
    )
    
    for package in "${gaming_packages[@]}"; do
        if ! pacman -Qs "$package" &> /dev/null; then
            log "Installing $package..."
            sudo pacman -S --noconfirm "$package" || warning "Failed to install $package"
        fi
    done
    
    # Install ProtonUp-Qt from AUR
    yay -S --noconfirm protonup-qt
    
    log "Gaming tools installed!"
}

# Install development tools
install_dev_tools() {
    if [[ "$INSTALL_DEV_TOOLS" != "y" ]]; then
        return
    fi
    
    log "Installing development tools..."
    
    local dev_packages=(
        "code"
        "git"
        "github-cli"
        "docker"
        "docker-compose"
        "nodejs"
        "npm"
        "python"
        "python-pip"
        "rustup"
        "go"
        "neovim"
        "tree-sitter"
        "ripgrep"
        "fd"
        "bat"
        "exa"
        "fzf"
        "tmux"
        "zellij"
    )
    
    for package in "${dev_packages[@]}"; do
        if ! pacman -Qs "$package" &> /dev/null; then
            log "Installing $package..."
            sudo pacman -S --noconfirm "$package" || warning "Failed to install $package"
        fi
    done
    
    # Enable Docker service
    sudo systemctl enable docker
    sudo usermod -aG docker "$USER"
    
    # Install Rust
    if command -v rustup &> /dev/null; then
        rustup default stable
    fi
    
    log "Development tools installed!"
}

# Fix common issues
fix_common_issues() {
    log "Applying common fixes..."
    
    # Fix audio issues
    systemctl --user enable pipewire pipewire-pulse wireplumber
    
    # Fix XDG portals
    mkdir -p "$CONFIG_DIR/xdg-desktop-portal"
    cat > "$CONFIG_DIR/xdg-desktop-portal/portals.conf" <<'EOF'
[preferred]
default=hyprland;gtk
org.freedesktop.impl.portal.Screenshot=hyprland
org.freedesktop.impl.portal.ScreenCast=hyprland
org.freedesktop.impl.portal.FileChooser=gtk
EOF

    # Fix environment variables for Wayland
    mkdir -p "$CONFIG_DIR/environment.d"
    cat > "$CONFIG_DIR/environment.d/wayland.conf" <<'EOF'
QT_QPA_PLATFORM=wayland
XDG_CURRENT_DESKTOP=Hyprland
XDG_SESSION_TYPE=wayland
XDG_SESSION_DESKTOP=Hyprland
MOZ_ENABLE_WAYLAND=1
EOF

    # Create desktop entry for Hyprland
    sudo mkdir -p /usr/share/wayland-sessions
    sudo tee /usr/share/wayland-sessions/hyprland.desktop > /dev/null <<'EOF'
[Desktop Entry]
Name=Hyprland
Comment=An intelligent dynamic tiling Wayland compositor
Exec=Hyprland
Type=Application
EOF

    log "Common fixes applied!"
}

# Post-installation setup
post_install_setup() {
    log "Performing post-installation setup..."
    
    # Download some default wallpapers
    mkdir -p "$HOME/Pictures/Wallpapers"
    if command -v wget &> /dev/null; then
        log "Downloading sample wallpapers..."
        cd "$HOME/Pictures/Wallpapers"
        
        # Download some free wallpapers (you can replace these URLs)
        wget -q "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=1920&h=1080&fit=crop" -O "mountain-lake.jpg" 2>/dev/null || true
        wget -q "https://images.unsplash.com/photo-1419242902214-272b3f66ee7a?w=1920&h=1080&fit=crop" -O "space.jpg" 2>/dev/null || true
        wget -q "https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=1920&h=1080&fit=crop" -O "forest.jpg" 2>/dev/null || true
        
        cd ~
    fi
    
    # Set up Fish shell completions
    if command -v fish &> /dev/null; then
        fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher" 2>/dev/null || true
    fi
    
    # Create autostart script
    cat > "$HOME/.local/bin/hypr-autostart" <<'EOF'
#!/bin/bash

# Hyprland autostart script
sleep 2

# Set wallpaper
if [ -d "$HOME/Pictures/Wallpapers" ] && [ "$(ls -A $HOME/Pictures/Wallpapers)" ]; then
    wallpaper random
fi

# Start additional services
pgrep -x waybar || waybar &
pgrep -x dunst || dunst &
EOF
    
    chmod +x "$HOME/.local/bin/hypr-autostart"
    
    log "Post-installation setup completed!"
}

# Create uninstall script
create_uninstall_script() {
    log "Creating uninstall script..."
    
    cat > "$HOME/uninstall-hyprland.sh" <<'EOF'
#!/bin/bash

# Hyprland Uninstall Script

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}⚠️  This will remove Hyprland and all related configurations!${NC}"
read -p "Are you sure you want to continue? (y/N): " confirm

if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "Uninstall cancelled."
    exit 0
fi

echo -e "${RED}Removing Hyprland packages...${NC}"

# Remove packages
packages_to_remove=(
    "hyprland"
    "waybar"
    "wofi"
    "dunst"
    "swww"
    "kitty"
    "rofi-wayland"
    "swaylock-effects"
    "wlogout"
    "hyprpicker"
    "hyprshot"
    "wlsunset"
    "nwg-look"
    "bibata-cursor-theme"
)

for package in "${packages_to_remove[@]}"; do
    if pacman -Qs "$package" &> /dev/null; then
        echo "Removing $package..."
        yay -Rns --noconfirm "$package" 2>/dev/null || sudo pacman -Rns --noconfirm "$package" 2>/dev/null || true
    fi
done

echo -e "${RED}Removing configuration files...${NC}"

# Remove configurations
rm -rf ~/.config/hypr
rm -rf ~/.config/waybar
rm -rf ~/.config/wofi
rm -rf ~/.config/dunst
rm -rf ~/.config/kitty
rm -rf ~/.config/fish
rm -rf ~/.config/starship.toml

# Remove scripts
rm -f ~/.local/bin/screenshot
rm -f ~/.local/bin/wallpaper
rm -f ~/.local/bin/system-update
rm -f ~/.local/bin/hypr-reload
rm -f ~/.local/bin/hypr-autostart

# Remove desktop entry
sudo rm -f /usr/share/wayland-sessions/hyprland.desktop

# Disable SDDM if it was installed
if systemctl is-enabled sddm &>/dev/null; then
    read -p "Disable SDDM display manager? (y/n): " disable_sddm
    if [[ "$disable_sddm" == "y" ]]; then
        sudo systemctl disable sddm
        echo "SDDM disabled. You may want to enable another display manager."
    fi
fi

echo -e "${GREEN}Hyprland has been uninstalled!${NC}"
echo "You may want to reboot your system."

# Remove this script
rm -f "$0"
EOF
    
    chmod +x "$HOME/uninstall-hyprland.sh"
    log "Uninstall script created at ~/uninstall-hyprland.sh"
}

# Main installation function
main() {
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                                                              ║${NC}"
    echo -e "${BLUE}║            🚀 Enhanced Hyprland Installer v2.0 🚀            ║${NC}"
    echo -e "${BLUE}║                                                              ║${NC}"
    echo -e "${BLUE}║          Complete Hyprland Desktop Environment Setup        ║${NC}"
    echo -e "${BLUE}║                                                              ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    
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
    install_gaming_tools
    install_dev_tools
    install_dotfiles
    fix_common_issues
    post_install_setup
    create_uninstall_script
    
    # Final message
    echo
    echo -e "${GREEN}🎉 Hyprland installation completed successfully!${NC}"
    echo
    echo -e "${BLUE}📋 Installation Summary:${NC}"
    echo -e "   • ${GREEN}✓${NC} Hyprland with optimized configuration"
    echo -e "   • ${GREEN}✓${NC} Waybar status bar with Catppuccin theme"
    echo -e "   • ${GREEN}✓${NC} Wofi and Rofi application launchers"
    echo -e "   • ${GREEN}✓${NC} Dunst notification daemon"
    echo -e "   • ${GREEN}✓${NC} Kitty terminal with Catppuccin theme"
    echo -e "   • ${GREEN}✓${NC} Fish shell with Starship prompt"
    echo -e "   • ${GREEN}✓${NC} Custom scripts and utilities"
    [[ "$INSTALL_SDDM" == "y" ]] && echo -e "   • ${GREEN}✓${NC} SDDM display manager configured"
    [[ "$INSTALL_NVIDIA" == "y" ]] && echo -e "   • ${GREEN}✓${NC} NVIDIA drivers for Wayland"
    [[ "$INSTALL_WAYDROID" == "y" ]] && echo -e "   • ${GREEN}✓${NC} Waydroid Android emulation"
    [[ "$INSTALL_GAMING" == "y" ]] && echo -e "   • ${GREEN}✓${NC} Gaming tools (Steam, Lutris, etc.)"
    [[ "$INSTALL_DEV_TOOLS" == "y" ]] && echo -e "   • ${GREEN}✓${NC} Development tools (VS Code, Docker, etc.)"
    
    echo
    echo -e "${YELLOW}📝 Next Steps:${NC}"
    echo -e "   1. ${CYAN}Reboot your system:${NC} ${GREEN}sudo reboot${NC}"
    [[ "$INSTALL_SDDM" == "y" ]] && echo -e "   2. ${CYAN}Select Hyprland from SDDM login screen${NC}"
    [[ "$INSTALL_SDDM" != "y" ]] && echo -e "   2. ${CYAN}Start Hyprland:${NC} ${GREEN}Hyprland${NC}"
    echo -e "   3. ${CYAN}Add wallpapers to${NC} ${GREEN}~/Pictures/Wallpapers/${NC}"
    echo -e "   4. ${CYAN}Customize configurations in${NC} ${GREEN}~/.config/${NC}"
    echo -e "   5. ${CYAN}Run${NC} ${GREEN}wallpaper random${NC} ${CYAN}to set a wallpaper${NC}"
    
    echo
    echo -e "${BLUE}🔧 Essential Keybindings:${NC}"
    echo -e "   • ${GREEN}Super + Q${NC} - Open terminal"
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
    
    echo
    echo -e "${BLUE}🛠️  Useful Scripts:${NC}"
    echo -e "   • ${GREEN}screenshot [area|window|full]${NC} - Take screenshots"
    echo -e "   • ${GREEN}wallpaper [random|current|list]${NC} - Manage wallpapers"
    echo -e "   • ${GREEN}system-update${NC} - Update system and AUR packages"
    echo -e "   • ${GREEN}hypr-reload${NC} - Reload Hyprland configuration"
    
    echo
    echo -e "${BLUE}📁 Important Directories:${NC}"
    echo -e "   • ${GREEN}~/.config/hypr/${NC} - Hyprland configuration"
    echo -e "   • ${GREEN}~/.config/waybar/${NC} - Status bar configuration"
    echo -e "   • ${GREEN}~/.config/kitty/${NC} - Terminal configuration"
    echo -e "   • ${GREEN}~/Pictures/Wallpapers/${NC} - Wallpaper directory"
    echo -e "   • ${GREEN}~/Pictures/Screenshots/${NC} - Screenshot directory"
    
    echo
    echo -e "${YELLOW}⚠️  Troubleshooting:${NC}"
    echo -e "   • If Waybar doesn't start: ${GREEN}waybar &${NC}"
    echo -e "   • If wallpaper doesn't load: ${GREEN}wallpaper random${NC}"
    echo -e "   • For NVIDIA issues: Check ~/.config/hypr/hyprland.conf"
    echo -e "   • To uninstall: ${GREEN}~/uninstall-hyprland.sh${NC}"
    
    echo
    echo -e "${BLUE}🔗 Resources:${NC}"
    echo -e "   • Hyprland Wiki: ${CYAN}https://wiki.hyprland.org/${NC}"
    echo -e "   • Catppuccin Theme: ${CYAN}https://github.com/catppuccin/catppuccin${NC}"
    echo -e "   • Waybar Modules: ${CYAN}https://github.com/Alexays/Waybar/wiki/Module:-Hyprland${NC}"
    echo -e "   • Fish Shell: ${CYAN}https://fishshell.com/docs/current/index.html${NC}"
    
    echo
    if [[ "$INSTALL_WAYDROID" == "y" ]]; then
        echo -e "${YELLOW}📱 Waydroid Setup:${NC}"
        echo -e "   After reboot, run: ${GREEN}sudo waydroid init${NC}"
        echo -e "   Then: ${GREEN}waydroid session start${NC}"
        echo
    fi
    
    if [[ "$INSTALL_GAMING" == "y" ]]; then
        echo -e "${YELLOW}🎮 Gaming Setup:${NC}"
        echo -e "   • Steam should work out of the box"
        echo -e "   • Use ${GREEN}gamemode${NC} for better performance"
        echo -e "   • Configure MangoHud for FPS overlay"
        echo -e "   • Use ProtonUp-Qt to manage Proton versions"
        echo
    fi
    
    if [[ "$INSTALL_DEV_TOOLS" == "y" ]]; then
        echo -e "${YELLOW}💻 Development Setup:${NC}"
        echo -e "   • You've been added to the docker group"
        echo -e "   • Rust toolchain installed via rustup"
        echo -e "   • VS Code ready for Wayland"
        echo -e "   • Neovim configured as default editor"
        echo
    fi
    
    echo -e "${GREEN}🚀 Enjoy your new Hyprland desktop environment!${NC}"
    echo -e "${BLUE}💡 Pro tip: Join the Hyprland Discord for community support${NC}"
    echo
    
    # Ask if user wants to reboot now
    read -p "Would you like to reboot now? (y/n): " reboot_now
    if [[ "$reboot_now" == "y" || "$reboot_now" == "Y" ]]; then
        log "Rebooting system..."
        sudo reboot
    else
        log "Installation complete! Please reboot when ready."
    fi
}

# Error handling
set -eE
trap 'error "Script failed at line $LINENO"' ERR

# Check if script is being sourced or executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
EOF
