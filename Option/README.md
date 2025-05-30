# 🚀 Enhanced Hyprland Installer v2.0

Complete Hyprland desktop environment setup for Arch Linux with Catppuccin theme.

## ✨ Features

- **Complete Hyprland setup** with optimized configuration
- **Catppuccin Mocha theme** across all applications
- **Waybar** with custom modules and styling
- **Wofi** application launcher
- **Dunst** notification daemon
- **Kitty** terminal with custom theme
- **Fish shell** with useful aliases and functions
- **Starship** prompt with custom configuration
- **Utility scripts** for screenshots, wallpapers, and system management
- **Optional components**: NVIDIA drivers, SDDM, gaming tools, development tools

## 📋 Prerequisites

- Arch Linux installation
- Internet connection
- Non-root user with sudo privileges

## 🔧 Installation

1. **Download the installer:**
```bash
git clone <repository-url>
cd hyprland-installer
```

2. **Make the script executable:**
```bash
chmod +x install-hyprland.sh
```

3. **Run the installer:**
```bash
./install-hyprland.sh
```

4. **Follow the prompts** to customize your installation

5. **Reboot** when prompted

## 🎮 Keybindings

### Application Shortcuts
- `Super + Q` - Terminal (Kitty)
- `Super + R` - Application launcher (Wofi)
- `Super + E` - File manager (Nautilus)
- `Super + C` - Close window
- `Super + M` - Exit Hyprland
- `Super + L` - Lock screen
- `Super + Shift + Q` - Power menu

### Window Management
- `Super + Arrow Keys` - Move focus
- `Super + Shift + Arrow Keys` - Move windows
- `Super + Ctrl + Arrow Keys` - Resize windows
- `Super + F` - Fullscreen
- `Super + V` - Toggle floating
- `Super + J` - Toggle split

### Workspaces
- `Super + 1-9` - Switch to workspace
- `Super + Shift + 1-9` - Move window to workspace
- `Super + S` - Toggle scratchpad
- `Super + Mouse Wheel` - Scroll through workspaces

### Screenshots
- `Print` - Region screenshot
- `Shift + Print` - Window screenshot
- `Ctrl + Print` - Fullscreen screenshot

### System Controls
- `Volume Up/Down` - Adjust volume
- `Brightness Up/Down` - Adjust brightness
- `Media Keys` - Control playback

## 📁 File Structure

```
~/.config/
├── hypr/hyprland.conf          # Hyprland configuration
├── waybar/
│   ├── config                  # Waybar configuration
│   └── style.css              # Waybar styling
├── wofi/
│   ├── config                  # Wofi configuration
│   └── style.css              # Wofi styling
├── dunst/dunstrc              # Notification configuration
├── kitty/kitty.conf           # Terminal configuration
├── fish/config.fish           # Shell configuration
└── starship.toml              # Prompt configuration

~/.local/bin/                   # Utility scripts
├── screenshot.sh
├── wallpaper-changer.sh
├── system-info.sh
├── power-menu.sh
└── volume-control.sh
```

## 🎨 Customization

### Changing Wallpapers
1. Place wallpapers in `~/Pictures/Wallpapers/`
2. Run `wallpaper-changer.sh` or use the keybinding
3. Wallpapers will cycle automatically

### Modifying Theme Colors
Edit the color values in:
- `~/.config/hypr/hyprland.conf` - Window borders and effects
- `~/.config/waybar/style.css` - Status bar colors
- `~/.config/wofi/style.css` - Launcher colors
- `~/.config/kitty/kitty.conf` - Terminal colors

### Adding Custom Keybindings
Edit `~/.config/hypr/hyprland.conf` and add:
```
bind = $mainMod, KEY, exec, COMMAND
```

## 🔧 Troubleshooting

### Common Issues

**Hyprland won't start:**
- Check logs: `journalctl -u display-manager`
- Verify GPU drivers are installed
- Check Hyprland config syntax

**No audio:**
```bash
systemctl --user enable --now pipewire pipewire-pulse
```

**Screen tearing:**
- Enable VRR in hyprland.conf: `vrr = 1`
- For NVIDIA: Add environment variables

**Applications not launching:**
- Check if applications are installed
- Verify PATH in shell configuration

**Waybar not showing:**
```bash
killall waybar
waybar &
```

### NVIDIA Specific Issues

**Cursor invisible:**
Add to hyprland.conf:
```
env = WLR_NO_HARDWARE_CURSORS,1
```

**Performance issues:**
```
env = __GL_GSYNC_ALLOWED,0
env = __GL_VRR_ALLOWED,0
```

## 📚 Useful Commands

### Hyprland Control
```bash
# Reload configuration
hyprctl reload

# Get window info
hyprctl activewindow

# List monitors
hyprctl monitors

# Kill a window
hyprctl kill

# Change workspace
hyprctl dispatch workspace 2
```

### System Information
```bash
# Run system info script
system-info.sh

# Check Wayland session
echo $XDG_SESSION_TYPE

# Monitor system resources
htop
```

### Package Management
```bash
# Update system
sudo pacman -Syu

# Install package
sudo pacman -S package_name

# Search packages
pacman -Ss search_term

# Remove package
sudo pacman -R package_name
```

## 🔄 Updates

To update the configuration:

1. **Backup current config:**
```bash
cp -r ~/.config/hypr ~/.config/hypr.backup
```

2. **Pull latest changes:**
```bash
git pull origin main
```

3. **Re-run installer or copy specific configs**

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📝 License

This project is licensed under the MIT License.

## 🙏 Acknowledgments

- [Hyprland](https://hyprland.org/) - Amazing Wayland compositor
- [Catppuccin](https://catppuccin.com/) - Beautiful color palette
- [Waybar](https://github.com/Alexays/Waybar) - Highly customizable status bar
- [Arch Linux](https://archlinux.org/) - The best Linux distribution

## 📞 Support

If you encounter issues:

1. Check the troubleshooting section
2. Search existing issues on GitHub
3. Create a new issue with:
   - System information
   - Error messages
   - Steps to reproduce

---

**Enjoy your new Hyprland setup! 🎉**
```
