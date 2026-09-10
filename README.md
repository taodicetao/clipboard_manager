# 📋 Clipboard Manager for macOS

<div align="center">

![macOS](https://img.shields.io/badge/macOS-15.5%2B-blue?style=flat-square)
![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange?style=flat-square)
![Build](https://img.shields.io/badge/Build-No%20Xcode%20needed-brightgreen?style=flat-square)
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

1. **Download** `ClipboardManager-1.0.dmg` from [GitHub Releases](https://github.com/taodicetao/clipboard_manager/releases)
2. **Drag** `ClipboardManager.app` into `Applications`
3. **Open** it. The app is not notarized with Apple, so the first launch is blocked:
   go to **System Settings → Privacy & Security** and click **Open Anyway**.
   If it still refuses to open, run:
   ```bash
   xattr -dr com.apple.quarantine /Applications/ClipboardManager.app
   ```
4. **Grant Accessibility** — required to send the paste keystroke:
   **System Settings → Privacy & Security → Accessibility** → enable `ClipboardManager`
5. Optional auto-start: **System Settings → General → Login Items → Open at Login → +**

Requires macOS 15.5 or later. Universal binary (Apple Silicon + Intel).

### 🛠️ For Developers

Xcode is **not** required — the build scripts use the Command Line Tools only
(`xcode-select --install`).

```bash
git clone https://github.com/taodicetao/clipboard_manager.git
cd clipboard_manager

# Build and install to /Applications
scripts/install.sh

# Build a distributable DMG in dist/
scripts/package-dmg.sh

# Build the .app only (SIGN_IDENTITY=- for ad-hoc, ARCHS to pick slices)
scripts/build-app.sh dist
```

Optional, recommended when rebuilding often: `scripts/setup-cert.sh` creates a
self-signed code-signing certificate in your login keychain. Builds signed with it keep
a stable identity, so macOS does not drop the Accessibility permission after every
rebuild. Without it the scripts sign ad-hoc, and the permission has to be re-granted
whenever the binary changes.

Opening `ClipboardManager.xcodeproj` in Xcode still works for editing and debugging.

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
# Build the .app (universal, ad-hoc signed) into dist/
SIGN_IDENTITY=- scripts/build-app.sh dist

# Build + package the DMG that ships to users
scripts/package-dmg.sh          # -> dist/ClipboardManager-<version>.dmg

# Build + install locally
scripts/install.sh
```

Version, bundle id and deployment target are read from
`ClipboardManager.xcodeproj/project.pbxproj`, so bumping `MARKETING_VERSION` there is
enough to rename the next DMG.

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

### App worked, then stopped launching after a while
Older builds were signed through Xcode automatic signing (Apple Development identity
plus an embedded provisioning profile). Both expire, and once they do macOS refuses to
launch the app. Current builds sign with a self-signed certificate valid for 100 years,
or ad-hoc, and the install scripts strip the quarantine attribute — nothing left to
expire. Reinstall with `scripts/install.sh`, or grab the latest DMG.

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