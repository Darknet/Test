#!/bin/bash
# Enhanced Hyprland Installation Script
# Combines best features from JaKooLit and ML4W dotfiles
# Author: Enhanced by Claude - Based on JaKooLit and ML4W dotfiles

clear

# Set colors for output messages
OK="$(tput setaf 2)[OK]$(tput sgr0)"
ERROR="$(tput setaf 1)[ERROR]$(tput sgr0)"
NOTE="$(tput setaf 3)[NOTE]$(tput sgr0)"
INFO="$(tput setaf 4)[INFO]$(tput sgr0)"
WARN="$(tput setaf 1)[WARN]$(tput sgr0)"
CAT="$(tput setaf 6)[ACTION]$(tput sgr0)"
MAGENTA="$(tput setaf 5)"
ORANGE="$(tput setaf 214)"
WARNING="$(tput setaf 1)"
YELLOW="$(tput setaf 3)"
GREEN="$(tput setaf 2)"
BLUE="$(tput setaf 4)"
SKY_BLUE="$(tput setaf 6)"
RESET="$(tput sgr0)"

# Create Directory for Install Logs
if [ ! -d Install-Logs ]; then
    mkdir Install-Logs
fi

LOG="Install-Logs/Enhanced-Hyprland-Install-$(date +%d-%H%M%S).log"

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    echo "${ERROR} This script should ${WARNING}NOT${RESET} be executed as root!! Exiting......." | tee -a "$LOG"
    exit 1
fi

# Check if PulseAudio is installed
if pacman -Qq | grep -qw '^pulseaudio$'; then
    echo "$ERROR PulseAudio detected. Please uninstall it first or configure the script to skip pipewire installation." | tee -a "$LOG"
    exit 1
fi

# Function to check if command exists
_checkCommandExists() {
    package="$1"
    if ! command -v $package >/dev/null; then
        return 1
    else
        return 0
    fi
}

# Function to install required packages
_installPackages() {
    toInstall=()
    for pkg; do
        if ! pacman -Qs "$pkg" > /dev/null; then
            toInstall+=("$pkg")
        fi
    done
    if [[ "${toInstall[@]}" != "" ]]; then
        sudo pacman --noconfirm -S "${toInstall[@]}"
    fi
}

# Install essential packages for the installer
essential_packages=(
    "base-devel"
    "git"
    "curl"
    "wget"
    "unzip"
    "rsync"
    "libnewt"
    "pciutils"
)

echo "${INFO} Installing essential packages..." | tee -a "$LOG"
_installPackages "${essential_packages[@]}"

clear

printf "\n%.0s" {1..2}  
echo -e "\e[35m
	╔═╗┌┐┌┬ ┬┌─┐┌┐┌┌─┐┌─┐┌┬┐  ╦ ╦┬ ┬┌─┐┬─┐┬  ┌─┐┌┐┌┌┬┐
	║╣ ││││├─┤├─┤││││  ├┤  ││  ╠═╣└┬┘├─┘├┬┘│  ├─┤│││ ││
	╚═╝┘└┘┴ ┴┴ ┴┘└┘└─┘└─┘─┴┘  ╩ ╩ ┴ ┴  ┴└─┴─┘┴ ┴┘└┘─┴┘
\e[0m"
printf "\n%.0s" {1..1} 

echo "Enhanced Hyprland Installation Script (2025)"
echo "Combining the best of JaKooLit and ML4W dotfiles"
printf "\n%.0s" {1..1}

# Welcome message using whiptail
whiptail --title "Enhanced Hyprland Install Script" \
    --msgbox "Welcome to the Enhanced Hyprland Installation Script!\n\n\
This script combines the best features from JaKooLit and ML4W dotfiles.\n\n\
IMPORTANT: \n\
- Run a full system update first\n\
- Backup your system (use timeshift/snapper)\n\
- If installing on VM, enable 3D acceleration\n\n\
Features:\n\
- NVIDIA and hybrid GPU support\n\
- Waydroid integration option\n\
- Multiple dotfile sources\n\
- Enhanced customization options" \
    20 80

# Ask if user wants to proceed
if ! whiptail --title "Proceed with Installation?" \
    --yesno "Would you like to proceed with the enhanced installation?" 8 50; then
    echo "${INFO} Installation cancelled by user" | tee -a "$LOG"
    exit 0
fi

# Detect GPU type
nvidia_detected=false
amd_detected=false
intel_detected=false
hybrid_gpu=false

if lspci | grep -i "nvidia" &> /dev/null; then
    nvidia_detected=true
fi

if lspci | grep -i "amd" &> /dev/null || lspci | grep -i "radeon" &> /dev/null; then
    amd_detected=true
fi

if lspci | grep -i "intel.*graphics" &> /dev/null; then
    intel_detected=true
fi

# Check for hybrid GPU setup
gpu_count=$(lspci | grep -E "(VGA|3D|Display)" | wc -l)
if [ "$gpu_count" -gt 1 ]; then
    hybrid_gpu=true
fi

# Display GPU information
gpu_info="Detected GPU configuration:\n\n"
[ "$nvidia_detected" = true ] && gpu_info+="✓ NVIDIA GPU detected\n"
[ "$amd_detected" = true ] && gpu_info+="✓ AMD GPU detected\n"
[ "$intel_detected" = true ] && gpu_info+="✓ Intel GPU detected\n"
[ "$hybrid_gpu" = true ] && gpu_info+="\n⚠️  Hybrid GPU setup detected"

whiptail --title "GPU Detection" --msgbox "$gpu_info" 12 60

# Check for AUR helper
aur_helper=""
if _checkCommandExists "yay"; then
    aur_helper="yay"
elif _checkCommandExists "paru"; then
    aur_helper="paru"
else
    aur_helper=$(whiptail --title "AUR Helper Selection" --menu "Select an AUR helper to install:" 12 60 2 \
        "yay" "Yet Another Yaourt (recommended)" \
        "paru" "Paru AUR helper" 3>&1 1>&2 2>&3)
    
    if [ $? -ne 0 ]; then
        echo "${ERROR} AUR helper selection cancelled" | tee -a "$LOG"
        exit 1
    fi
fi

# Install AUR helper if needed
if ! _checkCommandExists "$aur_helper"; then
    echo "${INFO} Installing $aur_helper..." | tee -a "$LOG"
    if [ "$aur_helper" = "yay" ]; then
        git clone https://aur.archlinux.org/yay.git /tmp/yay
        cd /tmp/yay
        makepkg -si --noconfirm
        cd -
        rm -rf /tmp/yay
    elif [ "$aur_helper" = "paru" ]; then
        git clone https://aur.archlinux.org/paru.git /tmp/paru
        cd /tmp/paru
        makepkg -si --noconfirm
        cd -
        rm -rf /tmp/paru
    fi
fi

# Options selection with enhanced features
options_command=(
    whiptail --title "Enhanced Installation Options" --checklist 
    "Select installation options (use SPACEBAR to select):" 25 90 18
)

# GPU-specific options
if [ "$nvidia_detected" = true ]; then
    options_command+=(
        "nvidia_drivers" "Install NVIDIA drivers for Wayland/Hyprland" "ON"
    )
    if [ "$hybrid_gpu" = true ]; then
        options_command+=(
            "nvidia_hybrid" "Configure hybrid GPU setup (optimus-manager)" "ON"
        )
    fi
fi

if [ "$amd_detected" = true ]; then
    options_command+=(
        "amd_drivers" "Install AMD drivers and AMDGPU optimizations" "ON"
    )
fi

# Core options
options_command+=(
    "waydroid" "Install Waydroid (Android emulation)" "OFF"
    "dotfiles_source" "Choose dotfiles source (will prompt later)" "ON"
    "sddm" "Install and configure SDDM login manager" "OFF"
    "sddm_theme" "Install additional SDDM themes" "OFF"
    "gtk_themes" "Install GTK themes and icons" "ON"
    "bluetooth" "Configure Bluetooth support" "ON"
    "audio_pipewire" "Install PipeWire audio system" "ON"
    "gaming_tools" "Install gaming tools (Steam, Lutris, etc.)" "OFF"
    "development_tools" "Install development tools" "OFF"
    "multimedia_codecs" "Install multimedia codecs" "ON"
    "fonts_enhanced" "Install enhanced font collection" "ON"
    "thunar" "Install Thunar file manager" "ON"
    "ags" "Install AGS for desktop overview" "ON"
    "zsh_ohmyzsh" "Install Zsh with Oh-My-Zsh" "ON"
    "fastfetch" "Install fastfetch system info" "ON"
)

# Get user selections
selected_options=$("${options_command[@]}" 3>&1 1>&2 2>&3)

if [ $? -ne 0 ]; then
    echo "${ERROR} Installation cancelled by user" | tee -a "$LOG"
    exit 1
fi

# Process selected options
IFS=' ' read -r -a options <<< "$(echo "$selected_options" | tr -d '"')"

# Dotfiles source selection
dotfiles_source=""
if [[ " ${options[@]} " =~ " dotfiles_source " ]]; then
    dotfiles_source=$(whiptail --title "Dotfiles Source" --menu "Choose your dotfiles source:" 15 70 3 \
        "jakoolit" "JaKooLit Hyprland-Dots (feature-rich)" \
        "ml4w" "ML4W Dotfiles (modern, clean)" \
        "both" "Install both (recommended for comparison)" 3>&1 1>&2 2>&3)
    
    if [ $? -ne 0 ]; then
        dotfiles_source="jakoolit"  # Default fallback
    fi
fi

# Waydroid architecture selection
waydroid_arch=""
if [[ " ${options[@]} " =~ " waydroid " ]]; then
    waydroid_arch=$(whiptail --title "Waydroid Architecture" --menu "Choose Waydroid system architecture:" 12 60 2 \
        "x86_64" "x86_64 (recommended for most systems)" \
        "arm64" "ARM64 (for ARM processors)" 3>&1 1>&2 2>&3)
    
    if [ $? -ne 0 ]; then
        waydroid_arch="x86_64"  # Default fallback
    fi
fi

# Confirmation
confirm_message="You have selected the following options:\n\n"
for option in "${options[@]}"; do
    confirm_message+=" ✓ $option\n"
done
[ -n "$dotfiles_source" ] && confirm_message+="\nDotfiles source: $dotfiles_source"
[ -n "$waydroid_arch" ] && confirm_message+="\nWaydroid architecture: $waydroid_arch"
confirm_message+="\n\nProceed with installation?"

if ! whiptail --title "Confirm Installation" --yesno "$confirm_message" 20 80; then
    echo "${ERROR} Installation cancelled by user" | tee -a "$LOG"
    exit 1
fi

echo "${OK} Starting enhanced Hyprland installation..." | tee -a "$LOG"

# Core package installation
echo "${INFO} Installing core Hyprland packages..." | tee -a "$LOG"

hyprland_packages=(
    "hyprland"
    "hyprpaper"
    "hyprlock"
    "hypridle"
    "hyprpicker"
    "xdg-desktop-portal-hyprland"
    "waybar"
    "rofi-wayland"
    "dunst"
    "kitty"
    "dolphin"
    "firefox"
    "brightnessctl"
    "playerctl"
    "grim"
    "slurp"
    "swappy"
    "cliphist"
    "wl-clipboard"
)

_installPackages "${hyprland_packages[@]}"

# Install selected components
for option in "${options[@]}"; do
    case "$option" in
        "nvidia_drivers")
            echo "${INFO} Installing NVIDIA drivers..." | tee -a "$LOG"
            nvidia_packages=(
                "nvidia-dkms"
                "nvidia-utils"
                "nvidia-settings"
                "libva-nvidia-driver"
                "egl-wayland"
            )
            _installPackages "${nvidia_packages[@]}"
            
            # Create NVIDIA environment variables
            mkdir -p ~/.config/hypr/conf.d
            cat > ~/.config/hypr/conf.d/nvidia.conf << 'EOF'
# NVIDIA-specific environment variables
env = LIBVA_DRIVER_NAME,nvidia
env = XDG_SESSION_TYPE,wayland
env = GBM_BACKEND,nvidia-drm
env = __GLX_VENDOR_LIBRARY_NAME,nvidia
env = WLR_NO_HARDWARE_CURSORS,1
env = ELECTRON_OZONE_PLATFORM_HINT,auto
EOF
            ;;
            
        "nvidia_hybrid")
            echo "${INFO} Installing hybrid GPU support..." | tee -a "$LOG"
            $aur_helper -S --noconfirm optimus-manager optimus-manager-qt
            ;;
            
        "amd_drivers")
            echo "${INFO} Installing AMD drivers..." | tee -a "$LOG"
            amd_packages=(
                "xf86-video-amdgpu"
                "vulkan-radeon"
                "libva-mesa-driver"
                "mesa-vdpau"
            )
            _installPackages "${amd_packages[@]}"
            ;;
            
        "waydroid")
            echo "${INFO} Installing Waydroid..." | tee -a "$LOG"
            $aur_helper -S --noconfirm waydroid python-pyclip
            
            # Initialize Waydroid
            sudo waydroid init -s GAPPS -f
            
            # Configure Waydroid for the selected architecture
            if [ "$waydroid_arch" = "arm64" ]; then
                sudo waydroid init -s GAPPS -f -a arm64
            fi
            
            # Enable Waydroid service
            sudo systemctl enable --now waydroid-container
            ;;
            
        "audio_pipewire")
            echo "${INFO} Installing PipeWire audio system..." | tee -a "$LOG"
            pipewire_packages=(
                "pipewire"
                "pipewire-pulse"
                "pipewire-audio"
                "pipewire-alsa"
                "pipewire-jack"
                "wireplumber"
                "pavucontrol"
                "pamixer"
            )
            _installPackages "${pipewire_packages[@]}"
            systemctl --user enable --now pipewire pipewire-pulse wireplumber
            ;;
            
        "sddm")
            echo "${INFO} Installing SDDM..." | tee -a "$LOG"
            _installPackages sddm qt5-graphicaleffects qt5-quickcontrols2
            sudo systemctl enable sddm
            ;;
            
        "sddm_theme")
            echo "${INFO} Installing SDDM themes..." | tee -a "$LOG"
            $aur_helper -S --noconfirm sddm-sugar-candy-git
            ;;
            
        "gtk_themes")
            echo "${INFO} Installing GTK themes..." | tee -a "$LOG"
            gtk_packages=(
                "gtk3"
                "gtk4"
                "adwaita-icon-theme"
                "papirus-icon-theme"
                "arc-gtk-theme"
                "materia-gtk-theme"
                "lxappearance"
                "qt5ct"
                "kvantum-qt5"
            )
            _installPackages "${gtk_packages[@]}"
            $aur_helper -S --noconfirm bibata-cursor-theme
            ;;
            
        "bluetooth")
            echo "${INFO} Configuring Bluetooth..." | tee -a "$LOG"
            bluetooth_packages=(
                "bluez"
                "bluez-utils"
                "blueman"
            )
            _installPackages "${bluetooth_packages[@]}"
            sudo systemctl enable --now bluetooth
            ;;
            
        "gaming_tools")
            echo "${INFO} Installing gaming tools..." | tee -a "$LOG"
            gaming_packages=(
                "steam"
                "lutris"
                "wine"
                "gamemode"
                "mangohud"
            )
            _installPackages "${gaming_packages[@]}"
            $aur_helper -S --noconfirm heroic-games-launcher-bin
            ;;
            
        "development_tools")
            echo "${INFO} Installing development tools..." | tee -a "$LOG"
            dev_packages=(
                "code"
                "git"
                "nodejs"
                "npm"
                "python"
                "python-pip"
                "docker"
                "docker-compose"
            )
            _installPackages "${dev_packages[@]}"
            sudo systemctl enable --now docker
            sudo usermod -aG docker $USER
            ;;
            
        "multimedia_codecs")
            echo "${INFO} Installing multimedia codecs..." | tee -a "$LOG"
            codec_packages=(
                "gst-plugins-base"
                "gst-plugins-good"
                "gst-plugins-bad"
                "gst-plugins-ugly"
                "gst-libav"
                "ffmpeg"
                "vlc"
            )
            _installPackages "${codec_packages[@]}"
            ;;
            
        "fonts_enhanced")
            echo "${INFO} Installing enhanced fonts..." | tee -a "$LOG"
            font_packages=(
                "ttf-dejavu"
                "ttf-liberation"
                "noto-fonts"
                "noto-fonts-emoji"
                "ttf-fira-code"
                "ttf-jetbrains-mono"
                "ttf-opensans"
            )
            _installPackages "${font_packages[@]}"
            $aur_helper -S --noconfirm ttf-ms-fonts nerd-fonts-fira-code
            ;;
            
        "thunar")
            echo "${INFO} Installing Thunar file manager..." | tee -a "$LOG"
            thunar_packages=(
                "thunar"
                "thunar-volman"
                "thunar-archive-plugin"
                "thunar-media-tags-plugin"
                "file-roller"
                "tumbler"
                "ffmpegthumbnailer"
            )
            _installPackages "${thunar_packages[@]}"
            ;;
            
        "ags")
            echo "${INFO} Installing AGS..." | tee -a "$LOG"
            $aur_helper -S --noconfirm ags
            ;;
            
        "zsh_ohmyzsh")
            echo "${INFO} Installing Zsh with Oh-My-Zsh..." | tee -a "$LOG"
            _installPackages zsh
            
            # Install Oh-My-Zsh
            sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
            
            # Change default shell
            chsh -s $(which zsh)
            ;;
            
        "fastfetch")
            echo "${INFO} Installing fastfetch..." | tee -a "$LOG"
            _installPackages fastfetch
            ;;
    esac
done

# Install dotfiles based on selection
if [ -n "$dotfiles_source" ]; then
    echo "${INFO} Installing dotfiles: $dotfiles_source..." | tee -a "$LOG"
    
    case "$dotfiles_source" in
        "jakoolit")
            # Clone and install JaKooLit dotfiles
            git clone --depth=1 https://github.com/JaKooLit/Hyprland-Dots.git /tmp/jakoolit-dots
            cd /tmp/jakoolit-dots
            chmod +x copy.sh
            ./copy.sh
            cd -
            rm -rf /tmp/jakoolit-dots
            ;;
            
        "ml4w")
            # Install ML4W dotfiles
            $aur_helper -S --noconfirm ml4w-hyprland
            ml4w-hyprland-setup -p arch
            ;;
            
        "both")
            echo "${INFO} Installing both dotfile sources..." | tee -a "$LOG"
            # Install ML4W first
            $aur_helper -S --noconfirm ml4w-hyprland
            
            # Then install JaKooLit (user can switch between them)
            git clone --depth=1 https://github.com/JaKooLit/Hyprland-Dots.git ~/.config/hypr-dots-jakoolit
            
            echo "${NOTE} Both dotfiles installed. ML4W is active. JaKooLit configs available in ~/.config/hypr-dots-jakoolit"
            ;;
    esac
fi

# Final system configuration
echo "${INFO} Performing final system configuration..." | tee -a "$LOG"

# Create basic Hyprland config if none exists
if [ ! -f ~/.config/hypr/hyprland.conf ]; then
    mkdir -p ~/.config/hypr
    cat > ~/.config/hypr/hyprland.conf << 'EOF'
# Enhanced Hyprland Configuration
source = ~/.config/hypr/conf.d/*.conf

# Monitor configuration (adjust as needed)
monitor=,preferred,auto,1

# Input configuration
input {
    kb_layout = us
    follow_mouse = 1
    touchpad {
        natural_scroll = yes
    }
    sensitivity = 0
}

# General configuration
general {
    gaps_in = 5
    gaps_out = 10
    border_size = 2
    col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
    col.inactive_border = rgba(595959aa)
    layout = dwindle
}

# Decoration
decoration {
    rounding = 10
    blur {
        enabled = true
        size = 3
        passes = 1
    }
    drop_shadow = yes
    shadow_range = 4
    shadow_render_power = 3
    col.shadow = rgba(1a1a1aee)
}

# Animations
animations {
    enabled = yes
    bezier = myBezier, 0.05, 0.9, 0.1, 1.05
    animation = windows, 1, 7, myBezier
    animation = windowsOut, 1, 7, default, popin 80%
    animation = border, 1, 10, default
    animation = borderangle, 1, 8, default
    animation = fade, 1, 7, default
    animation = workspaces, 1, 6, default
}

# Dwindle layout
dwindle {
    no_gaps_when_only = false
    pseudotile = yes
    preserve_split = yes
}

# Window rules
windowrule = float, ^(pavucontrol)$
windowrule = float, ^(blueman-manager)$
windowrule = float, ^(nm-connection-editor)$

# Key bindings
$mainMod = SUPER

bind = $mainMod, Return, exec, kitty
bind = $mainMod, Q, killactive,
bind = $mainMod, M, exit,
bind = $mainMod, E, exec, thunar
bind = $mainMod, V, togglefloating,
bind = $mainMod, R, exec, rofi -show drun
bind = $mainMod, P, pseudo, # dwindle
bind = $mainMod, J, togglesplit, # dwindle

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

# Scroll through workspaces
bind = $mainMod, mouse_down, workspace, e+1
bind = $mainMod, mouse_up, workspace, e-1

# Move/resize windows
bindm = $mainMod, mouse:272, movewindow
bindm = $mainMod, mouse:273, resizewindow

# Screenshot bindings
bind = , Print, exec, grim -g "$(slurp)" - | swappy -f -
bind = SHIFT, Print, exec, grim - | swappy -f -

# Audio bindings
bind = , XF86AudioRaiseVolume, exec, pamixer -i 5
bind = , XF86AudioLowerVolume, exec, pamixer -d 5
bind = , XF86AudioMute, exec, pamixer -t

# Brightness bindings
bind = , XF86MonBrightnessUp, exec, brightnessctl s +5%
bind = , XF86MonBrightnessDown, exec, brightnessctl s 5%-

# Media bindings
bind = , XF86AudioPlay, exec, playerctl play-pause
bind = , XF86AudioNext, exec, playerctl next
bind = , XF86AudioPrev, exec, playerctl previous

# Startup applications
exec-once = waybar
exec-once = dunst
exec-once = hyprpaper
exec-once = hypridle
exec-once = /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1
exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
EOF
fi

# Set up auto-login to Hyprland if no display manager is active
if ! systemctl is-active --quiet gdm && ! systemctl is-active --quiet sddm && ! systemctl is-active --quiet lightdm; then
    if [ ! -f ~/.zprofile ]; then
        echo 'if [ -z "$WAYLAND_DISPLAY" ] && [ "$XDG_VTNR" -eq 1 ]; then exec Hyprland; fi' >> ~/.zprofile
    fi
fi

echo "${OK} Enhanced Hyprland installation completed!" | tee -a "$LOG"

# Summary and next steps
whiptail --title "Installation Complete!" --msgbox "Enhanced Hyprland installation completed successfully!\n\n\
Next steps:\n\
1. Reboot your system (recommended)\n\
2. Log into Hyprland session\n\
3. Configure your monitors and preferences\n\n\
Useful keybindings:\n\
- SUPER + Return: Terminal\n\
- SUPER + R: Application launcher\n\
- SUPER + Q: Close window\n\
- SUPER + E: File manager\n\
- Print: Screenshot\n\n\
Check the installation logs in Install-Logs/ for details." 20 80

# Offer to reboot
if whiptail --title "Reboot System?" --yesno "Would you like to reboot now to complete the installation?" 8 60; then
    echo "${INFO} Rebooting system..." | tee -a "$LOG"
    systemctl reboot
else
    echo "${NOTE} Please reboot your system manually when ready." | tee -a "$LOG"
fi

echo "${OK} Installation script finished. Enjoy your Enhanced Hyprland setup!" | tee -a "$LOG"