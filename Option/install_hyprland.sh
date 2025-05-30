#!/bin/bash

# Enhanced Hyprland Installer v2.0
# Arch Linux Hyprland Desktop Environment Setup

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
CONFIG_DIR="$HOME/.config"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Logging functions
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# Check if running on Arch Linux
check_arch() {
    if [[ ! -f /etc/arch-release ]]; then
        error "This script is designed for Arch Linux only!"
    fi
    
    if [[ $EUID -eq 0 ]]; then
        error "Do not run this script as root!"
    fi
}

# Ask user preferences
ask_user_preferences() {
    echo -e "${BLUE}🔧 Installation Options${NC}"
    echo
    
    read -p "Install NVIDIA drivers for Wayland? (y/n): " INSTALL_NVIDIA
    read -p "Install SDDM display manager? (y/n): " INSTALL_SDDM
    read -p "Install Waydroid (Android emulation)? (y/n): " INSTALL_WAYDROID
    read -p "Install gaming tools (Steam, Lutris, etc.)? (y/n): " INSTALL_GAMING
    read -p "Install development tools (VS Code, Docker, etc.)? (y/n): " INSTALL_DEV_TOOLS
    
    echo
}

# Install base packages
install_base_packages() {
    log "Updating system and installing base packages..."
    
    sudo pacman -Syu --noconfirm
    
    local base_packages=(
        "hyprland"
        "waybar"
        "wofi"
        "dunst"
        "swww"
        "kitty"
        "fish"
        "starship"
        "pipewire"
        "pipewire-pulse"
        "pipewire-alsa"
        "wireplumber"
        "xdg-desktop-portal-hyprland"
        "xdg-desktop-portal-gtk"
        "qt5-wayland"
        "qt6-wayland"
        "polkit-kde-agent"
        "noto-fonts"
        "noto-fonts-emoji"
        "ttf-fira-code"
        "papirus-icon-theme"
        "grim"
        "slurp"
        "wl-clipboard"
        "brightnessctl"
        "playerctl"
        "pavucontrol"
        "network-manager-applet"
        "bluez"
        "bluez-utils"
        "blueman"
        "firefox"
        "nautilus"
        "imagemagick"
        "wget"
        "curl"
        "git"
        "unzip"
        "htop"
        "neofetch"
    )
    
    for package in "${base_packages[@]}"; do
        if ! pacman -Qs "$package" &> /dev/null; then
            log "Installing $package..."
            sudo pacman -S --noconfirm "$package" || warning "Failed to install $package"
        fi
    done
}

# Install AUR helper and packages
install_aur_packages() {
    log "Installing AUR helper and packages..."
    
    # Install yay if not present
    if ! command -v yay &> /dev/null; then
        log "Installing yay AUR helper..."
        git clone https://aur.archlinux.org/yay.git /tmp/yay
        cd /tmp/yay
        makepkg -si --noconfirm
        cd ~
        rm -rf /tmp/yay
    fi
    
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
    
    local nvidia_packages=(
        "nvidia"
        "nvidia-utils"
        "lib32-nvidia-utils"
        "nvidia-settings"
    )
    
    for package in "${nvidia_packages[@]}"; do
        sudo pacman -S --noconfirm "$package" || warning "Failed to install $package"
    done
    
    # Add nvidia modules to mkinitcpio
    sudo sed -i 's/MODULES=()/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf
    sudo mkinitcpio -P
    
    # Add kernel parameters
    if [[ -f /boot/loader/entries/arch.conf ]]; then
        sudo sed -i 's/options root=/options nvidia-drm.modeset=1 root=/' /boot/loader/entries/arch.conf
    fi
}

# Install display manager
install_display_manager() {
    if [[ "$INSTALL_SDDM" != "y" ]]; then
        return
    fi
    
    log "Installing and configuring SDDM..."
    
    sudo pacman -S --noconfirm sddm
    sudo systemctl enable sddm
    
    # Configure SDDM
    sudo mkdir -p /etc/sddm.conf.d
    sudo tee /etc/sddm.conf.d/hyprland.conf > /dev/null <<EOF
[General]
DisplayServer=wayland
GreeterEnvironment=QT_WAYLAND_SHELL_INTEGRATION=layer-shell

[Wayland]
CompositorCommand=Hyprland
EOF
}

# Install Waydroid
install_waydroid_support() {
    if [[ "$INSTALL_WAYDROID" != "y" ]]; then
        return
    fi
    
    log "Installing Waydroid..."
    
    sudo pacman -S --noconfirm waydroid
    yay -S --noconfirm waydroid-image-gapps
}

# Install gaming tools
install_gaming_tools() {
    if [[ "$INSTALL_GAMING" != "y" ]]; then
        return
    fi
    
    log "Installing gaming tools..."
    
    # Enable multilib
    sudo sed -i '/\[multilib\]/,/Include/s/^#//' /etc/pacman.conf
    sudo pacman -Sy
    
    local gaming_packages=(
        "steam"
        "lutris"
        "gamemode"
        "lib32-gamemode"
        "mangohud"
        "lib32-mangohud"
        "wine"
        "winetricks"
    )
    
    for package in "${gaming_packages[@]}"; do
        sudo pacman -S --noconfirm "$package" || warning "Failed to install $package"
    done
    
    yay -S --noconfirm protonup-qt
}

# Install development tools
install_dev_tools() {
    if [[ "$INSTALL_DEV_TOOLS" != "y" ]]; then
        return
    fi
    
    log "Installing development tools..."
    
    local dev_packages=(
        "code"
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
    )
    
    for package in "${dev_packages[@]}"; do
        sudo pacman -S --noconfirm "$package" || warning "Failed to install $package"
    done
    
    sudo systemctl enable docker
    sudo usermod -aG docker "$USER"
    
    if command -v rustup &> /dev/null; then
        rustup default stable
    fi
}

# Copy configuration files
copy_configurations() {
    log "Copying configuration files..."
    
    # Create directories
    mkdir -p "$CONFIG_DIR"/{hypr,waybar,wofi,dunst,kitty,fish}
    mkdir -p "$HOME/Pictures"/{Wallpapers,Screenshots}
    mkdir -p "$HOME/.local/bin"
    
    # Copy config files if they exist
    if [[ -f "$SCRIPT_DIR/hyprland.conf" ]]; then
        cp "$SCRIPT_DIR/hyprland.conf" "$CONFIG_DIR/hypr/"
        log "Copied Hyprland configuration"
    fi
    
    if [[ -f "$SCRIPT_DIR/waybar-config.json" ]]; then
        cp "$SCRIPT_DIR/waybar-config.json" "$CONFIG_DIR/waybar/config"
        log "Copied Waybar configuration"
    fi
    
    if [[ -f "$SCRIPT_DIR/waybar-style.css" ]]; then
        cp "$SCRIPT_DIR/waybar-style.css" "$CONFIG_DIR/waybar/style.css"
        log "Copied Waybar styles"
    fi
    
    if [[ -f "$SCRIPT_DIR/wofi-config" ]]; then
        cp "$SCRIPT_DIR/wofi-config" "$CONFIG_DIR/wofi/config"
        log "Copied Wofi configuration"
    fi
    
    if [[ -f "$SCRIPT_DIR/wofi-style.css" ]]; then
        cp "$SCRIPT_DIR/wofi-style.css" "$CONFIG_DIR/wofi/style.css"
        log "Copied Wofi styles"
    fi
    
    if [[ -f "$SCRIPT_DIR/dunstrc" ]]; then
        cp "$SCRIPT_DIR/dunstrc" "$CONFIG_DIR/dunst/"
        log "Copied Dunst configuration"
    fi
    
    if [[ -f "$SCRIPT_DIR/kitty.conf" ]]; then
        cp "$SCRIPT_DIR/kitty.conf" "$CONFIG_DIR/kitty/"
        log "Copied Kitty configuration"
    fi
    
    if [[ -f "$SCRIPT_DIR/fish-config.fish" ]]; then
        cp "$SCRIPT_DIR/fish-config.fish" "$CONFIG_DIR/fish/config.fish"
        log "Copied Fish configuration"
    fi
    
    if [[ -f "$SCRIPT_DIR/starship.toml" ]]; then
        cp "$SCRIPT_DIR/starship.toml" "$CONFIG_DIR/"
        log "Copied Starship configuration"
    fi
    
    # Copy scripts
    if [[ -d "$SCRIPT_DIR/scripts" ]]; then
        cp "$SCRIPT_DIR/scripts/"* "$HOME/.local/bin/"
        chmod +x "$HOME/.local/bin/"*
        log "Copied utility scripts"
    fi
}

# Download wallpapers
download_wallpapers() {
    log "Downloading sample wallpapers..."
    
    cd "$HOME/Pictures/Wallpapers"
    
    wget -q "https://picsum.photos/1920/1080?random=1" -O "wallpaper1.jpg" 2>/dev/null || true
    wget -q "https://picsum.photos/1920/1080?random=2" -O "wallpaper2.jpg" 2>/dev/null || true
    wget -q "https://picsum.photos/1920/1080?random=3" -O "wallpaper3.jpg" 2>/dev/null || true
    
    if command -v convert &> /dev/null; then
        convert -size 1920x1080 gradient:"#89b4fa"-"#cba6f7" "gradient-blue-purple.png" 2>/dev/null || true
        convert -size 1920x1080 gradient:"#f38ba8"-"#fab387" "gradient-pink-orange.png" 2>/dev/null || true
    fi
    
    cd ~
}

# Set Fish as default shell
setup_fish_shell() {
    if command -v fish &> /dev/null; then
        if [[ "$SHELL" != *"fish"* ]]; then
            log "Setting Fish as default shell..."
            chsh -s $(which fish)
        fi
    fi
}

# Fix common issues
fix_common_issues() {
    log "Applying common fixes..."
    
    # Enable audio services
    systemctl --user enable pipewire pipewire-pulse wireplumber
    
    # XDG portals
    mkdir -p "$CONFIG_DIR/xdg-desktop-portal"
    cat > "$CONFIG_DIR/xdg-desktop-portal/portals.conf" <<EOF
[preferred]
default=hyprland;gtk
org.freedesktop.impl.portal.Screenshot=hyprland
org.freedesktop.impl.portal.ScreenCast=hyprland
org.freedesktop.impl.portal.FileChooser=gtk
EOF

    # Environment variables
    mkdir -p "$CONFIG_DIR/environment.d"
    cat > "$CONFIG_DIR/environment.d/wayland.conf" <<EOF
QT_QPA_PLATFORM=wayland
XDG_CURRENT_DESKTOP=Hyprland
XDG_SESSION_TYPE=wayland
XDG_SESSION_DESKTOP=Hyprland
MOZ_ENABLE_WAYLAND=1
EOF

    # Desktop entry
    sudo mkdir -p /usr/share/wayland-sessions
    sudo tee /usr/share/wayland-sessions/hyprland.desktop > /dev/null <<EOF
[Desktop Entry]
Name=Hyprland
Comment=An intelligent dynamic tiling Wayland compositor
Exec=Hyprland
Type=Application
EOF
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
    
    check_arch
    ask_user_preferences
    
    install_base_packages
    install_aur_packages
    install_nvidia_drivers
    install_display_manager
    install_waydroid_support
    install_gaming_tools
    install_dev_tools
    copy_configurations
    download_wallpapers
    # ... (continuación del script principal)

boot_now" ]]; then
        sudo reboot
    fi
}

# Run main function
main "$@"

