# 📋 Clipboard Manager for macOS

<div align="center">

![macOS](https://img.shields.io/badge/macOS-13.0%2B-blue?style=flat-square)
![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange?style=flat-square)
![Xcode](https://img.shields.io/badge/Xcode-15.0%2B-blue?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)

**A lightweight, powerful clipboard manager that lives in your menu bar**

[Features](#-features) • [Installation](#-installation) • [Usage](#-usage) • [Development](#-development) • [Contributing](#-contributing)

</div>

---

## ✨ Features

<table>
<tr>
<td width="50%">

### 🎯 Core Functionality
- **Global Hotkey** - `⌘ + ;` for instant access
- **Smart Storage** - Keeps your last 20 clipboard items
- **Multi-format Support** - Text, images, and files
- **Intelligent Positioning** - Panel appears at cursor location

</td>
<td width="50%">

### 🚀 User Experience
- **Menu Bar Integration** - Minimal, unobtrusive design
- **Background Agent** - No dock icon clutter
- **Real-time Updates** - Live clipboard monitoring
- **Keyboard Navigation** - Full keyboard control

</td>
</tr>
</table>

## 📦 Installation

### 🎨 For Users

<details>
<summary><b>Download & Install (Click to expand)</b></summary>

1. **Download** the latest release from [GitHub Releases](https://github.com/YOUR_USERNAME/ClipboardManager/releases)
2. **Drag** `ClipboardManager.app` to your `/Applications` folder
3. **Launch** the app from Applications
4. **Configure** auto-start (optional):
   ```
   System Settings → General → Login Items → Add ClipboardManager.app
   ```

</details>

### 🛠️ For Developers

<details>
<summary><b>Build from Source (Click to expand)</b></summary>

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/ClipboardManager.git
cd ClipboardManager

# Open in Xcode
open ClipboardManager.xcodeproj

# Build and run (or press ⌘+R in Xcode)
xcodebuild -scheme ClipboardManager build
```

#### Prerequisites
- **macOS 13.0+** (Ventura or later)
- **Xcode 15.0+**
- **Swift 5.9+**

</details>

## 🎮 Usage

### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `⌘ + ;` | Open clipboard panel |
| `↑` / `↓` | Navigate items |
| `Enter` | Paste selected item |
| `Esc` | Close panel |
| `Right-click` | Close panel (in panel area) |

### Menu Bar Actions

Click the clipboard icon in your menu bar to:
- View recent items
- Access settings
- Quit the application

## 💻 Development

### Project Architecture

```
ClipboardManager/
├── 📱 Core Application
│   └── ClipboardManagerApp.swift      # Main app entry & AppDelegate
│
├── 📊 Data Layer
│   └── Models/
│       └── ClipboardItem.swift        # Clipboard data models
│
├── ⚙️ Services
│   └── Services/
│       └── PasteboardService.swift    # System clipboard monitoring
│
├── 🎨 User Interface
│   └── Views/
│       ├── ContentView.swift          # Main window (settings)
│       ├── QuickSelectView.swift      # Floating panel UI
│       └── SettingsView.swift         # Preferences panel
│
├── 🔧 System Integration
│   └── Managers/
│       ├── GlobalHotkeyManager.swift  # Global hotkey handling
│       ├── CursorPositionManager.swift# Cursor position detection
│       └── FloatingClipboardPanel.swift# NSPanel window management
│
└── 🎨 Resources
    ├── Assets.xcassets/               # Icons and images
    └── Info.plist                     # App configuration
```

### Building & Distribution

```bash
# Clean build
xcodebuild clean build

# Create archive for distribution
xcodebuild archive \
  -scheme ClipboardManager \
  -archivePath ./build/ClipboardManager.xcarchive

# Export for distribution
xcodebuild -exportArchive \
  -archivePath ./build/ClipboardManager.xcarchive \
  -exportPath ./build \
  -exportOptionsPlist ExportOptions.plist
```

### System Permissions

The app requires the following permissions:

| Permission | Purpose |
|------------|---------|
| **Accessibility** | Detect cursor position for smart panel placement |
| **Background Execution** | Monitor clipboard changes continuously |
| **Global Keyboard Events** | Register and respond to hotkey |

## 🐛 Troubleshooting

<details>
<summary><b>Common Issues & Solutions</b></summary>

### App doesn't start automatically
```bash
# Verify Login Items
System Settings → General → Login Items

# Check Info.plist configuration
defaults read /Applications/ClipboardManager.app/Contents/Info.plist LSUIElement
# Should return: 1
```

### Hotkey not responding
1. Check **Accessibility permissions** in System Settings
2. Restart the app: `killall ClipboardManager && open -a ClipboardManager`
3. Re-register hotkey by quitting and restarting

### Icons not displaying
```bash
# Clear icon cache
sudo rm -rf /Library/Caches/com.apple.iconservices.store
killall Dock && killall Finder

# Clean Xcode build
rm -rf ~/Library/Developer/Xcode/DerivedData
```

</details>

## 🤝 Contributing

We welcome contributions! Here's how you can help:

1. **Fork** the repository
2. **Create** your feature branch
   ```bash
   git checkout -b feature/amazing-feature
   ```
3. **Commit** your changes
   ```bash
   git commit -m 'Add: Amazing new feature'
   ```
4. **Push** to your branch
   ```bash
   git push origin feature/amazing-feature
   ```
5. **Open** a Pull Request

### Contribution Guidelines

- Follow Swift style guidelines
- Add tests for new features
- Update documentation as needed
- Keep commits atomic and descriptive

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

<div align="center">

**Created with ❤️ by TaoDice** 🎲

Built with **SwiftUI** and **AppKit** for the best native macOS experience

---

<sub>If you find this project useful, please consider giving it a ⭐ on GitHub!</sub>

</div>