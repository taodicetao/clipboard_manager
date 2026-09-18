# 📋 Clipboard Manager for macOS

<div align="center">

![macOS](https://img.shields.io/badge/macOS-15.5%2B-blue?style=flat-square)
![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange?style=flat-square)
![Build](https://img.shields.io/badge/Build-No%20Xcode%20needed-brightgreen?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)

**A lightweight clipboard history manager that lives in your menu bar — with a Liquid Glass panel on macOS 26**

[Features](#-features) • [Installation](#-installation) • [Usage](#-usage) • [Development](#-development) • [Contributing](#-contributing)

</div>

---

## ✨ Features

<table>
<tr>
<td width="50%">

### 🎯 Core
- **Global shortcut** — `⌘ ;` by default, change it in Settings
- **Persistent history** — survives quit and restart, up to 200 items
- **Text, images and files** — with a thumbnail for images
- **Source app** — every item shows the app it was copied from
- **Smart de-duplication** — copying something again moves it to the top

</td>
<td width="50%">

### 🚀 Experience
- **Liquid Glass panel** on macOS 26+, material panel on macOS 15
- **Type to search** the moment the panel opens
- **`⌘1`–`⌘9`** paste an item directly, **`⌫`** removes one
- **Privacy** — password managers are never recorded, and you can exclude any app
- **Launch at login** from Settings, no dock icon

</td>
</tr>
</table>

## 🆕 What's new in 2.0

- Liquid Glass floating panel (macOS 26) that stays open while you work — draggable, with a native close button
- History persists across restarts; images and files included
- Configurable global shortcut with a recorder that rejects macOS system shortcuts
- Source app shown on every item; exclude apps you never want recorded; password managers skipped automatically
- `⌘1`–`⌘9` paste directly, `⌫` removes, type-to-search on open
- Settings window (General · History · Privacy), Launch at Login, English-only UI
- Regression test suite (`swift test`) and a UI smoke test — no Xcode required

## 📦 Installation

### 🎨 For Users

1. **Download** `ClipboardManager-<version>.dmg` from [GitHub Releases](https://github.com/taodicetao/clipboard_manager/releases)
2. **Drag** `ClipboardManager.app` into `Applications`
3. **Open** it. The app is not notarized with Apple, so the first launch is blocked:
   go to **System Settings → Privacy & Security** and click **Open Anyway**.
   If it still refuses to open, run:
   ```bash
   xattr -dr com.apple.quarantine /Applications/ClipboardManager.app
   ```
4. **Grant Accessibility** — needed only so the app can send the `⌘V` keystroke when you pick an item.
   macOS asks the first time you paste; or go to **System Settings → Privacy & Security → Accessibility** and enable `ClipboardManager`.
   Without it the item is still copied to the clipboard, you just paste it yourself.
5. Optional: menu bar icon → **Settings… → General → Launch at login**

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
a stable identity, so macOS does not drop the Accessibility permission (and the login
item) after every rebuild. Without it the scripts sign ad-hoc, and the permission has to
be re-granted whenever the binary changes.

Opening `ClipboardManager.xcodeproj` in Xcode still works for editing and debugging.

## 🎮 Usage

### The panel

| Key | Action |
|-----|--------|
| `⌘ ;` | Open the panel at the mouse pointer — press again to move it there (configurable) |
| Type | Filter the history — the search field is focused when the panel opens |
| `↑` / `↓` | Move the selection |
| `↩` | Paste the selected item (or copy only, see Settings) |
| `⌘1` … `⌘9` | Paste item 1–9 directly |
| `⌫` / `⌘⌫` | Remove the selected item |
| `Esc` | Clear the search, then close |
| Right-click | Paste · Copy · Delete |

The panel floats above other windows and stays open while you work — drag it by the header
edge or the footer, and close it with the close button or `Esc`.

### Menu bar

Click the clipboard icon to show the panel, clear the history, open **Settings…**, or quit.

### Settings

| Tab | What you can change |
|-----|---------------------|
| **General** | Launch at login · keyboard shortcut · panel position (at the mouse pointer or centered) · focus search on open · paste immediately or copy only |
| **History** | Keep up to 20 / 50 / 100 / 200 items · keep history across restarts · capture images · notifications |
| **Privacy** | Apps whose clipboard content is never recorded |

Concealed and transient clipboard content (the convention used by 1Password and other
password managers) is always skipped, whatever the settings.

History is stored in `~/Library/Application Support/com.TaoDice.ClipboardManager/`
(`history.json` plus one PNG per image). Turning **Keep history across restarts** off
deletes it.

## 💻 Development

### Project Architecture

```
ClipboardManager/
├── App/
│   ├── ClipboardManagerApp.swift      # MenuBarExtra + Settings scenes
│   ├── AppDelegate.swift              # Composition root: creates and wires every service
│   └── StatusMenu.swift               # Menu bar menu
│
├── Models/
│   ├── ClipboardItem.swift            # Text / image / file item
│   ├── Hotkey.swift                   # Key code + Carbon modifiers
│   └── PanelPosition.swift
│
├── Services/
│   ├── AppSettings.swift              # @Observable settings backed by UserDefaults
│   ├── PasteboardService.swift        # Polls the pasteboard, filters, de-duplicates
│   ├── HistoryStore.swift             # history.json + images/, debounced atomic writes
│   ├── GlobalHotkeyManager.swift      # Carbon hotkey registration
│   ├── PasteSimulator.swift           # Sends ⌘V, checks Accessibility trust
│   ├── LoginItemService.swift         # SMAppService wrapper
│   └── AppInfoCache.swift             # App icons and names by bundle id
│
├── Support/
│   └── Observation.swift              # observeChanges(): react to @Observable changes
│
├── Views/
│   ├── Panel/                         # Floating panel (NSPanel + SwiftUI content)
│   │   ├── PanelBackdropView.swift    # NSGlassEffectView (26+) / NSVisualEffectView (15)
│   │   ├── ClipboardPanel.swift
│   │   ├── ClipboardPanelController.swift
│   │   ├── PanelKeyRouter.swift       # Keyboard events → commands
│   │   ├── PanelState.swift
│   │   ├── PanelView.swift
│   │   └── PanelItemRow.swift
│   ├── Settings/                      # General · History · Privacy tabs
│   └── Components/                    # Hotkey recorder, key caps, app icons, prompts
│
├── Assets.xcassets/
└── Info.plist
```

Services react to settings through Swift Observation (`observeChanges`), and the panel
reads `PasteboardService.clipboardItems` directly — there is no notification bus.

### Building & Distribution

```bash
# Build the .app (universal, ad-hoc signed) into dist/
SIGN_IDENTITY=- scripts/build-app.sh dist

# Build + package the DMG that ships to users
scripts/package-dmg.sh          # -> dist/ClipboardManager-<version>.dmg

# Build + install locally
scripts/install.sh
```

Version, bundle id, copyright and deployment target are read from
`ClipboardManager.xcodeproj/project.pbxproj`, so bumping `MARKETING_VERSION` there is
enough to rename the next DMG. Source files are discovered recursively, so new folders
need no script changes.

**Toolchain note.** With the macOS 27 SDK, SwiftUI's `@State` is implemented as a macro
whose plugin ships only inside Xcode. The Command Line Tools cannot expand it, so this
codebase keeps view state in `@Observable` objects and AppKit views instead of `@State`.
Keep it that way if you want the no-Xcode build to keep working.

### Testing

```bash
# Unit / regression tests (Swift Testing, runs with the Command Line Tools alone)
swift test

# UI smoke test against the installed app: opens the panel, checks it survives app
# switches, the close button, Settings, and the shortcut recorder. Needs Accessibility
# access for your terminal; keep your hands off the keyboard while it runs.
scripts/ui-smoke.sh
```

`swift test` covers the capture pipeline (text, files, images, de-duplication, concealed
content, excluded apps, trimming), persistence, settings migration, the shortcut model
and the panel's keyboard routing. Run both before tagging a release.

### App icon

Generate full-bleed artwork with the prompt in `docs/app-icon-prompt.md`, then run
`scripts/make-app-icon.swift path/to/artwork.png` — it trims, applies Apple's icon shape
and writes every size into the asset catalog.

### System Permissions

| Permission | Purpose | Required? |
|------------|---------|-----------|
| **Accessibility** | Send the `⌘V` keystroke after you pick an item | Only for *Paste selected item immediately* |
| **Notifications** | Optional alert when a new item is captured | Only if you turn the setting on |

The global shortcut and clipboard monitoring need no permission.

## 🐛 Troubleshooting

<details>
<summary><b>Common Issues & Solutions</b></summary>

### Picking an item copies it but does not paste
Accessibility access is missing or was reset by a rebuild.
**System Settings → Privacy & Security → Accessibility** → enable `ClipboardManager`.
Developers: sign with `scripts/setup-cert.sh` so the permission survives rebuilds.

### The shortcut does nothing
Another app probably registered the same global shortcut — macOS delivers it to only one
of them and cannot tell us which. Record a different combination in Settings → General.
Shortcuts that belong to macOS itself (⌘Space, ⌘Tab, …) are rejected while recording.
Restarting the app also re-registers the shortcut:
```bash
killall ClipboardManager && open -a ClipboardManager
```

### Something I copied is not in the history
- Copied from an app listed under Settings → Privacy → Excluded Apps
- Copied from a password manager (concealed content is never recorded)
- Images larger than 10 MB, or *Capture images* is off
- The source app is attributed from the frontmost app when the change is detected (polling every 0.5 s); switching apps immediately after copying can misattribute an item

### Launch at login stays off
Move the app to `/Applications` first. If the toggle shows *Waiting for approval*, allow
it in **System Settings → General → Login Items**. Ad-hoc signed rebuilds change the
app's identity and can drop the login item — use `scripts/setup-cert.sh`.

### App worked, then stopped launching after a while
Older builds were signed through Xcode automatic signing (Apple Development identity
plus an embedded provisioning profile). Both expire, and once they do macOS refuses to
launch the app. Current builds sign with a self-signed certificate valid for 100 years,
or ad-hoc, and the install scripts strip the quarantine attribute — nothing left to
expire. Reinstall with `scripts/install.sh`, or grab the latest DMG.

### Icons not displaying
```bash
# Clear icon cache
sudo rm -rf /Library/Caches/com.apple.iconservices.store
killall Dock && killall Finder
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
   git commit -m 'feat: add amazing feature'
   ```
4. **Push** to your branch
   ```bash
   git push origin feature/amazing-feature
   ```
5. **Open** a Pull Request

### Contribution Guidelines

- Follow Swift style guidelines
- Keep `swift test` and `scripts/build-app.sh` green — they are the release gate
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
