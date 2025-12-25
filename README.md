# 🚀 SharpShell

A modern, beautiful, and highly customizable shell/launcher system for Quickshell with full Wayland support. Features smooth animations, intuitive navigation, and powerful system integration.

![SharpShell](https://img.shields.io/badge/SharpShell-QML-blue)
![Quickshell](https://img.shields.io/badge/Quickshell-Compatible-green)
![Wayland](https://img.shields.io/badge/Wayland-Supported-purple)

## ✨ Features

### 🎯 Application Launcher
- **Fast Search**: Real-time filtering of applications
- **Keyboard Navigation**: Full arrow key support
- **Smooth Animations**: Beautiful transitions and hover effects
- **Package Management**: Install/remove packages via Pacman and AUR
- **Settings Panel**: Customize wallpaper, colors, and system updates
- **Color Presets**: 24 beautiful color themes to choose from
- **Custom Colors**: Edit HEX values for complete customization

### 📊 Dashboard
- **Modern Dashboard Interface**: Beautiful translucent dashboard with rounded corners
- **Tab Navigation**: Dashboard, Media, Performance, and Workspaces tabs
- **Weather Display**: Current temperature and conditions
- **System Information**: OS info, uptime, and system stats
- **Calendar View**: Large date display with monthly calendar grid
- **Resource Monitoring**: Real-time CPU, RAM, and Disk usage with vertical bars
- **Media Player Control**: Play, pause, skip tracks with album art and visual feedback
- **Pastel Color Scheme**: Soft cream and rose color palette

### 🎨 Side Panel
- **Audio Visualizer**: Real-time audio visualization with cava
- **Volume Control**: Adjust system volume with visual slider
- **Bluetooth Control**: Toggle Bluetooth on/off
- **Modern Design**: Clean, minimal interface

### 🖼️ Wallpaper Management
- **Native Quickshell Integration**: Set wallpapers directly through Quickshell (no external tools required!)
- **Visual Grid**: Browse wallpapers in a beautiful grid layout
- **Quick Preview**: Hover effects for easy selection
- **Smooth Transitions**: Fade animations when changing wallpapers
- **Multi-Screen Support**: Automatic synchronization across all screens
- **Fallback Support**: Optional support for swww, wbg, and hyprpaper
- **Dynamic Layout**: Auto-adjusting grid with smooth animations

## 📋 Requirements

### Required
- **Quickshell** - QML-based shell system
- **Wayland Compositor** - Tested with Hyprland

### Optional (for additional features)
- **cava** - Audio visualizer (for side panel visualization)
- **playerctl** - Media player control (for top menu media controls)
- **pactl** - PulseAudio volume control (for volume slider)
- **bluetoothctl** - Bluetooth management (for Bluetooth controls)
- **swww**, **wbg**, or **hyprpaper** - External wallpaper tools (optional fallback, native Quickshell wallpaper system works without them!)


## 🛠️ Installation

### 1. Clone the Repository

```bash
git clone https://github.com/artwik22/sharpshell.git ~/.config/sharpshell
cd ~/.config/sharpshell
```

### 2. Make Scripts Executable

```bash
chmod +x scripts/*.sh
chmod +x *.sh
```

### 3. Configure Quickshell

Make sure Quickshell is configured to use `shell.qml` as the main configuration file. The path should point to:

```
~/.config/sharpshell/shell.qml
```

### 4. Set Up Wallpapers Directory

Create the wallpapers directory (or change the path in `AppLauncher.qml`):

```bash
mkdir -p ~/Pictures/Wallpapers
```

## 🎮 Usage

### Keyboard Shortcuts Configuration

**Important**: You need to bind keyboard shortcuts in your Wayland compositor (e.g., Hyprland) to launch the scripts. Add these bindings to your compositor config:

**For Hyprland** (`~/.config/hyprland/hyprland.conf`):
```ini
# Open Launcher
bind = SUPER, R, exec, ~/.config/sharpshell/open-launcher.sh

# Toggle Top Menu
bind = SUPER, M, exec, ~/.config/sharpshell/toggle-menu.sh
```

**For other compositors**: Configure similar bindings to execute the scripts from `~/.config/sharpshell/`.

### Keyboard Shortcuts (Inside Launcher/Menu)

- **Open Launcher**: Use your configured shortcut (e.g., `Super+R`)
- **Toggle Top Menu**: Use your configured shortcut (e.g., `Super+M`)
- **Navigate**: Arrow keys (`↑`, `↓`, `←`, `→`)
- **Select**: `Enter` or `Space`
- **Search**: Start typing to filter
- **Escape**: Close launcher/menu

### Navigation


## 📁 Project Structure

```
sharpshell/
├── shell.qml                 # Main entry point
├── components/
│   ├── AppLauncher.qml       # Application launcher
│   ├── Dashboard.qml         # Dashboard with tabs and cards
│   ├── SidePanel.qml         # Side panel with visualizer
│   ├── VolumeSlider.qml      # Volume control component
│   ├── WallpaperBackground.qml # Native wallpaper background (Quickshell)
│   ├── Utils.qml             # Utility functions
│   ├── TopEdgeDetector.qml   # Top edge detection
│   └── RightEdgeDetector.qml # Right edge detection
├── scripts/
│   ├── start-cava.sh         # Audio visualizer startup
│   ├── install-package.sh    # Pacman package installation
│   ├── install-aur-package.sh # AUR package installation
│   ├── remove-package.sh     # Package removal
│   ├── remove-aur-package.sh # AUR package removal
│   └── update-system.sh      # System update script
├── open-launcher.sh          # Launcher opener script
├── toggle-menu.sh            # Menu toggle script
└── run.sh                   # Main runner script
```

## 🎨 Customization

### Colors and Styling

SharpShell includes a powerful color customization system:

- **24 Color Presets**: Choose from beautiful pre-made themes (Dark, Ocean, Forest, Violet, Crimson, Amber, Teal, Rose, Sunset, Midnight, Emerald, Lavender, Sapphire, Coral, Mint, Plum, Gold, Monochrome, Cherry, Azure, Jade, Ruby, Indigo)
- **Custom HEX Colors**: Edit individual color values (Background, Primary, Secondary, Text, Focus/Accent)
- **Live Preview**: See changes instantly as you edit
- **Persistent Settings**: Colors are saved to `~/.config/sharpshell/colors.json`

Edit the QML files in `components/` to customize:
- Font sizes and families
- Border radius and spacing
- Animation durations and easing

### Layout and Sizing

- **Launcher Size**: Modify `implicitWidth` and `implicitHeight` in `AppLauncher.qml`
- **Wallpaper Grid**: Adjust `cellWidth` and `cellHeight` in wallpaper picker
- **Dashboard Size**: Change dimensions in `Dashboard.qml`

### Behavior

- **Animation Speed**: Adjust `duration` in `Behavior` and `NumberAnimation` blocks
- **Hover Effects**: Modify `scale` values in hover handlers
- **Keyboard Shortcuts**: Configure in your compositor settings

## 🔧 Configuration

### Wallpapers Path

Default path: `~/Pictures/Wallpapers`

To change, edit in `AppLauncher.qml`:
```qml
property string wallpapersPath: "/your/custom/path"
```

**Note**: SharpShell uses native Quickshell wallpaper system (no external tools required!). The wallpaper is set via `WallpaperBackground.qml` component using `WlrLayer.Background`. If you prefer external tools, SharpShell will automatically detect and use `swww`, `wbg`, or `hyprpaper` if available.

### Audio Visualizer

The visualizer uses `cava` with automatic configuration. To customize, edit `scripts/start-cava.sh`.

### Package Management

Scripts support both Pacman and AUR (via `yay` or `paru`). Make sure you have an AUR helper installed.

## 🐛 Troubleshooting

### Launcher Not Appearing

- Check Quickshell configuration
- Verify `shell.qml` path is correct
- Check keyboard shortcut binding

### Visualizer Not Working

- Ensure `cava` is installed: `sudo pacman -S cava`
- Check if `/tmp/quickshell_cava` is being created
- Verify PulseAudio is running

### Wallpapers Not Loading

- Check wallpapers directory exists
- Verify file permissions
- Wallpapers work natively through Quickshell (no external tools needed!)
- If using external tools, ensure `swww`, `wbg`, or `hyprpaper` is installed

### Keyboard Focus Issues

- Try clicking on the launcher window
- Check Wayland compositor focus settings

## 📝 License

MIT License - feel free to use, modify, and distribute.

## 🤝 Contributing

Contributions are welcome! Feel free to:
- Report bugs
- Suggest features
- Submit pull requests
- Improve documentation

## 🙏 Acknowledgments

- Built with [Quickshell](https://github.com/Quickshell/Quickshell)
- Audio visualization powered by [cava](https://github.com/karlstav/cava)
- Wallpaper system inspired by [Caelestia Shell](https://github.com/caelestia-dots/shell)
- Optional wallpaper tools: [swww](https://github.com/Horus645/swww), [wbg](https://github.com/djpohly/wbg), [hyprpaper](https://github.com/hyprwm/hyprpaper)

---

**Made with ❤️ for the Linux community**
