#!/bin/bash
# Post-installation script for additional customizations

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() {
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                  HYPRLAND POST-INSTALL SETUP                ║"
    echo "║                     Additional Customizations               ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_step() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to install additional themes
install_additional_themes() {
    print_step "Installing additional GTK and icon themes..."
    
    # GTK themes
    yay -S --noconfirm \
        catppuccin-gtk-theme-mocha \
        papirus-icon-theme \
        catppuccin-cursors-mocha \
        bibata-cursor-theme
    
    # Set GTK theme
    gsettings set org.gnome.desktop.interface gtk-theme "catppuccin-mocha-standard-blue-dark"
    gsettings set org.gnome.desktop.interface icon-theme "Papirus-Dark"
    gsettings set org.gnome.desktop.interface cursor-theme "catppuccin-mocha-dark-cursors"
    
    print_success "Additional themes installed and configured"
}

# Function to setup development environment
setup_development() {
    print_step "Setting up development environment..."
    
    # Install development tools
    yay -S --noconfirm \
        visual-studio-code-bin \
        neovim \
        docker \
        docker-compose \
        nodejs \
        npm \
        python-pip \
        rustup \
        go
    
    # Setup Rust
    rustup default stable
    
    # Setup Docker
    sudo systemctl enable docker
    sudo usermod -aG docker $USER
    
    # Install VS Code extensions
    code --install-extension catppuccin.catppuccin-vsc
    code --install-extension ms-vscode.vscode-icons
    code --install-extension rust-lang.rust-analyzer
    code --install-extension ms-python.python
    
    print_success "Development environment configured"
}

# Function to install multimedia tools
install_multimedia() {
    print_step "Installing multimedia applications..."
    
    yay -S --noconfirm \
        vlc \
        gimp \
        obs-studio \
        audacity \
        blender \
        krita \
        inkscape \
        spotify \
        discord
    
    print_success "Multimedia applications installed"
}

# Function to setup gaming environment
setup_gaming() {
    print_step "Setting up gaming environment..."
    
    # Install gaming tools
    yay -S --noconfirm \
        steam \
        lutris \
        wine \
        winetricks \
        gamemode \
        lib32-gamemode \
        mangohud \
        lib32-mangohud \
        protonup-qt
    
    # Enable multilib repository if not already enabled
    if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
        print_step "Enabling multilib repository..."
        echo -e "\n[multilib]\nInclude = /etc/pacman.d/mirrorlist" | sudo tee -a /etc/pacman.conf
        sudo pacman -Sy
    fi
    
    print_success "Gaming environment configured"
}

# Function to install productivity tools
install_productivity() {
    print_step "Installing productivity applications..."
    
    yay -S --noconfirm \
        firefox \
        thunderbird \
        libreoffice-fresh \
        obsidian \
        notion-app \
        slack-desktop \
        zoom \
        teams
    
    print_success "Productivity applications installed"
}

# Function to setup additional fonts
install_fonts() {
    print_step "Installing additional fonts..."
    
    yay -S --noconfirm \
        ttf-fira-code \
        ttf-jetbrains-mono \
        ttf-roboto \
        ttf-opensans \
        noto-fonts \
        noto-fonts-emoji \
        ttf-liberation \
        ttf-dejavu \
        adobe-source-code-pro-fonts
    
    # Refresh font cache
    fc-cache -fv
    
    print_success "Additional fonts installed"
}

# Function to setup dotfiles backup
setup_dotfiles_backup() {
    print_step "Setting up dotfiles backup system..."
    
    # Create dotfiles directory
    mkdir -p ~/dotfiles
    
    # Create backup script
    cat > ~/dotfiles/backup.sh << 'EOF'
#!/bin/bash
# Dotfiles backup script

DOTFILES_DIR="$HOME/dotfiles"
CONFIG_DIR="$HOME/.config"

# Create directories
mkdir -p "$DOTFILES_DIR/config"

# Backup configurations
cp -r "$CONFIG_DIR/hypr" "$DOTFILES_DIR/config/"
cp -r "$CONFIG_DIR/waybar" "$DOTFILES_DIR/config/"
cp -r "$CONFIG_DIR/wofi" "$DOTFILES_DIR/config/"
cp -r "$CONFIG_DIR/dunst" "$DOTFILES_DIR/config/"
cp -r "$CONFIG_DIR/kitty" "$DOTFILES_DIR/config/"
cp -r "$CONFIG_DIR/fish" "$DOTFILES_DIR/config/"
cp "$CONFIG_DIR/starship.toml" "$DOTFILES_DIR/config/"

# Backup scripts
cp -r "$HOME/.local/bin" "$DOTFILES_DIR/"

echo "Dotfiles backed up to $DOTFILES_DIR"
EOF
    
    chmod +x ~/dotfiles/backup.sh
    
    print_success "Dotfiles backup system created"
}

# Function to optimize system performance
optimize_system() {
    print_step "Applying system optimizations..."
    
    # Create custom kernel parameters
    sudo tee /etc/sysctl.d/99-hyprland.conf << EOF
# Hyprland optimizations
vm.swappiness=10
vm.vfs_cache_pressure=50
kernel.sched_autogroup_enabled=0
EOF
    
    # Setup zram
    yay -S --noconfirm zram-generator
    
    sudo tee /etc/systemd/zram-generator.conf << EOF
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
EOF
    
    # Enable services
    sudo systemctl enable systemd-oomd
    sudo systemctl enable fstrim.timer
    
    print_success "System optimizations applied"
}
# Function to create useful aliases and functions (continuación)
create_aliases() {
    print_step "Creating additional aliases and functions..."
    
    # Add to fish config
    cat >> ~/.config/fish/config.fish << 'EOF'

# Additional aliases
alias hypr-edit='$EDITOR ~/.config/hypr/hyprland.conf'
alias waybar-edit='$EDITOR ~/.config/waybar/config'
alias fish-edit='$EDITOR ~/.config/fish/config.fish'
alias reload-waybar='killall waybar; waybar &'
alias reload-dunst='killall dunst; dunst &'

# System maintenance
alias cleanup='sudo pacman -Rns (pacman -Qtdq); sudo pacman -Sc'
alias update-all='yay -Syu --noconfirm'
alias check-errors='journalctl -p 3 -xb'

# Git shortcuts
alias glog='git log --oneline --graph --decorate --all'
alias gstash='git stash'
alias gpop='git stash pop'

# Docker shortcuts
alias dps='docker ps'
alias dimg='docker images'
alias dstop='docker stop (docker ps -q)'
alias dclean='docker system prune -af'

# Functions for Hyprland
function hypr-monitor
    hyprctl monitors -j | jq '.[] | {name: .name, resolution: (.width|tostring) + "x" + (.height|tostring), refresh: .refreshRate}'
end

function hypr-workspace
    hyprctl workspaces -j | jq '.[] | {id: .id, monitor: .monitor, windows: .windows}'
end

function hypr-window
    hyprctl clients -j | jq '.[] | {class: .class, title: .title, workspace: .workspace.id}'
end

function backup-config
    set backup_dir ~/config-backup-(date +%Y%m%d-%H%M%S)
    mkdir -p $backup_dir
    cp -r ~/.config/hypr $backup_dir/
    cp -r ~/.config/waybar $backup_dir/
    cp -r ~/.config/wofi $backup_dir/
    cp -r ~/.config/dunst $backup_dir/
    cp -r ~/.config/kitty $backup_dir/
    cp -r ~/.config/fish $backup_dir/
    cp ~/.config/starship.toml $backup_dir/
    echo "Configuration backed up to $backup_dir"
end

function restore-config
    if test (count $argv) -eq 0
        echo "Usage: restore-config <backup-directory>"
        return 1
    end
    
    set backup_dir $argv[1]
    if test -d $backup_dir
        cp -r $backup_dir/* ~/.config/
        echo "Configuration restored from $backup_dir"
        echo "Please restart Hyprland to apply changes"
    else
        echo "Backup directory not found: $backup_dir"
    end
end

function weather-widget
    curl -s "wttr.in?format=3"
end

function system-stats
    echo "CPU: "(cat /proc/loadavg | awk '{print $1}')
    echo "Memory: "(free | awk 'NR==2{printf "%.1f%%", $3*100/$2}')
    echo "Disk: "(df -h / | awk 'NR==2{print $5}')
end
EOF
    
    print_success "Additional aliases and functions created"
}

# Function to setup automatic wallpaper rotation
setup_wallpaper_rotation() {
    print_step "Setting up automatic wallpaper rotation..."
    
    # Create wallpaper rotation script
    cat > ~/.local/bin/wallpaper-rotation.sh << 'EOF'
#!/bin/bash
# Automatic wallpaper rotation script

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
INTERVAL=1800  # 30 minutes

while true; do
    if [ -d "$WALLPAPER_DIR" ]; then
        WALLPAPER=$(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.bmp" \) | shuf -n 1)
        if [ -n "$WALLPAPER" ]; then
            swww img "$WALLPAPER" --transition-type random --transition-duration 3
        fi
    fi
    sleep $INTERVAL
done
EOF
    
    chmod +x ~/.local/bin/wallpaper-rotation.sh
    
    # Create systemd user service
    mkdir -p ~/.config/systemd/user
    cat > ~/.config/systemd/user/wallpaper-rotation.service << 'EOF'
[Unit]
Description=Automatic Wallpaper Rotation
After=graphical-session.target

[Service]
Type=simple
ExecStart=%h/.local/bin/wallpaper-rotation.sh
Restart=always
RestartSec=10

[Install]
WantedBy=default.target
EOF
    
    # Enable the service
    systemctl --user enable wallpaper-rotation.service
    
    print_success "Automatic wallpaper rotation configured"
}

# Function to setup system monitoring
setup_monitoring() {
    print_step "Setting up system monitoring tools..."
    
    # Install monitoring tools
    yay -S --noconfirm \
        btop \
        neofetch \
        lm_sensors \
        smartmontools \
        iotop \
        nethogs
    
    # Create system monitoring script
    cat > ~/.local/bin/system-monitor.sh << 'EOF'
#!/bin/bash
# System monitoring dashboard

clear
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                    SYSTEM MONITORING                        ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo

# System info
neofetch --config none --ascii_distro arch_small

echo
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                      LIVE STATS                             ║"
echo "╚══════════════════════════════════════════════════════════════╝"

# CPU temperature
if command -v sensors >/dev/null 2>&1; then
    echo "🌡️  CPU Temperature:"
    sensors | grep -E "(Core|Package)" | head -4
    echo
fi

# GPU info (if NVIDIA)
if command -v nvidia-smi >/dev/null 2>&1; then
    echo "🎮 GPU Status:"
    nvidia-smi --query-gpu=name,temperature.gpu,utilization.gpu,memory.used,memory.total --format=csv,noheader,nounits
    echo
fi

# Network usage
echo "🌐 Network Usage:"
cat /proc/net/dev | grep -E "(wlan|eth|enp)" | head -2 | awk '{print $1 " RX: " $2/1024/1024 " MB, TX: " $10/1024/1024 " MB"}'
echo

# Top processes
echo "🔝 Top Processes:"
ps aux --sort=-%cpu | head -6 | awk 'NR==1{print $0} NR>1{printf "%-10s %5s %5s %s\n", $1, $3"%", $4"%", $11}'
EOF
    
    chmod +x ~/.local/bin/system-monitor.sh
    
    print_success "System monitoring tools configured"
}

# Function to create maintenance scripts
create_maintenance_scripts() {
    print_step "Creating system maintenance scripts..."
    
    # System cleanup script
    cat > ~/.local/bin/system-cleanup.sh << 'EOF'
#!/bin/bash
# System cleanup and maintenance script

echo "🧹 Starting system cleanup..."

# Clean package cache
echo "Cleaning package cache..."
sudo pacman -Sc --noconfirm

# Remove orphaned packages
echo "Removing orphaned packages..."
orphans=$(pacman -Qtdq)
if [ -n "$orphans" ]; then
    sudo pacman -Rns $orphans --noconfirm
else
    echo "No orphaned packages found"
fi

# Clean AUR cache
echo "Cleaning AUR cache..."
yay -Sc --noconfirm

# Clean systemd journal
echo "Cleaning systemd journal..."
sudo journalctl --vacuum-time=2weeks

# Clean temporary files
echo "Cleaning temporary files..."
sudo rm -rf /tmp/*
rm -rf ~/.cache/thumbnails/*

# Clean trash
echo "Emptying trash..."
rm -rf ~/.local/share/Trash/*

# Update file database
echo "Updating file database..."
sudo updatedb

echo "✅ System cleanup completed!"
EOF
    
    chmod +x ~/.local/bin/system-cleanup.sh
    
    # System update script
    cat > ~/.local/bin/system-update.sh << 'EOF'
#!/bin/bash
# System update script

echo "🔄 Starting system update..."

# Update package databases
echo "Updating package databases..."
sudo pacman -Sy

# Update system packages
echo "Updating system packages..."
sudo pacman -Su --noconfirm

# Update AUR packages
echo "Updating AUR packages..."
yay -Su --noconfirm

# Update flatpak packages (if installed)
if command -v flatpak >/dev/null 2>&1; then
    echo "Updating Flatpak packages..."
    flatpak update -y
fi

# Update firmware (if fwupd is installed)
if command -v fwupdmgr >/dev/null 2>&1; then
    echo "Checking for firmware updates..."
    fwupdmgr refresh
    fwupdmgr update
fi

echo "✅ System update completed!"
echo "💡 Consider rebooting if kernel was updated"
EOF
    
    chmod +x ~/.local/bin/system-update.sh
    
    # Backup script
    cat > ~/.local/bin/backup-system.sh << 'EOF'
#!/bin/bash
# System backup script

BACKUP_DIR="$HOME/Backups/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "💾 Starting system backup to $BACKUP_DIR..."

# Backup configurations
echo "Backing up configurations..."
cp -r ~/.config "$BACKUP_DIR/"
cp -r ~/.local/bin "$BACKUP_DIR/"

# Backup important files
echo "Backing up important files..."
cp -r ~/Documents "$BACKUP_DIR/" 2>/dev/null || true
cp -r ~/Pictures "$BACKUP_DIR/" 2>/dev/null || true
cp -r ~/Desktop "$BACKUP_DIR/" 2>/dev/null || true

# Create package list
echo "Creating package list..."
pacman -Qqe > "$BACKUP_DIR/pacman-packages.txt"
pacman -Qqm > "$BACKUP_DIR/aur-packages.txt"

# Backup crontab
echo "Backing up crontab..."
crontab -l > "$BACKUP_DIR/crontab.txt" 2>/dev/null || true

# Create restore script
cat > "$BACKUP_DIR/restore.sh" << 'RESTORE_EOF'
#!/bin/bash
# Restore script

echo "🔄 Restoring system from backup..."

# Restore configurations
cp -r .config/* ~/.config/
cp -r .local/bin/* ~/.local/bin/

# Install packages
sudo pacman -S --needed - < pacman-packages.txt
yay -S --needed - < aur-packages.txt

# Restore crontab
crontab crontab.txt

echo "✅ Restore completed!"
RESTORE_EOF

chmod +x "$BACKUP_DIR/restore.sh"

echo "✅ Backup completed at $BACKUP_DIR"
EOF
    
    chmod +x ~/.local/bin/backup-system.sh
    
    print_success "Maintenance scripts created"
}

# Main menu function
show_menu() {
    clear
    print_header
    echo
    echo "Select additional components to install:"
    echo
    echo "1) Additional Themes & Icons"
    echo "2) Development Environment"
    echo "3) Multimedia Applications"
    echo "4) Gaming Environment"
    echo "5) Productivity Applications"
    echo "6) Additional Fonts"
    echo "7) Dotfiles Backup System"
    echo "8) System Optimizations"
    echo "9) Enhanced Aliases & Functions"
    echo "10) Wallpaper Rotation"
    echo "11) System Monitoring Tools"
    echo "12) Maintenance Scripts"
    echo "13) Install All"
    echo "14) Exit"
    echo
    read -p "Enter your choice (1-14): " choice
}

# Main execution
main() {
    while true; do
        show_menu
        case $choice in
            1)
                install_additional_themes
                ;;
            2)
                setup_development
                ;;
            3)
                install_multimedia
                ;;
            4)
                setup_gaming
                ;;
            5)
                install_productivity
                ;;
            6)
                install_fonts
                ;;
            7)
                setup_dotfiles_backup
                ;;
            8)
                optimize_system
                ;;
            9)
                create_aliases
                ;;
            10)
                setup_wallpaper_rotation
                ;;
            11)
                setup_monitoring
                ;;
            12)
                create_maintenance_scripts
                ;;
            13)
                install_additional_themes
                setup_development
                install_multimedia
                setup_gaming
                install_productivity
                install_fonts
                setup_dotfiles_backup
                optimize_system
                create_aliases
                setup_wallpaper_rotation
                setup_monitoring
                create_maintenance_scripts
                ;;
            14)
                print_success "Post-installation setup completed!"
                exit 0
                ;;
            *)
                print_error "Invalid option. Please try again."
                ;;
        esac
        
        echo
        read -p "Press Enter to continue..."
    done
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    print_error "This script should not be run as root"
    exit 1
fi

# Run main function
main

