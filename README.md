# SelectTranslate - One-Click Installer

Translate text selected in chrome, websites and PDF files.

## Quick Install

### Windows
1. Right-click `windows/install.bat` → **Run as administrator**
2. Install the Chrome extension (load unpacked)
3. Restart Chrome completely
4. Click **▶ Play** to start translating!

> **Note:** The extension starts **PAUSED** by default to save resources.
> Click the extension icon and press ▶ to enable translation.

### macOS
```bash
cd macos
chmod +x install.sh
./install.sh
```
Then grant Accessibility permission when prompted.

### Linux
```bash
cd linux
chmod +x install.sh
./install.sh
```

## How It Works

```
┌─────────────────────────────────────────┐
│  Select text in chrome                  │
│  (include PDF files)                    │
└────────────────┬────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────┐
│  Native Host (Python)                   │
│  Detects selection → Sends to Chrome    │
│  Only runs when extension is ACTIVE     │
└────────────────┬────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────┐
│  Chrome Extension                       │
│  Translates → Shows popup               │
└─────────────────────────────────────────┘
```

## Pause / Resume

| State | Badge | Native Host | Resource Usage |
|-------|-------|-------------|----------------|
| **Paused** (default) | ⏸ | Not running | Zero |
| **Active** | (none) | Running | Normal |

- Press **Ctrl+Shift+P** to toggle pause/resume
- Or click the extension icon and use the ⏸/▶ button

## What Gets Installed

| Component | Location |
|-----------|----------|
| Native Host | `C:\Program Files\SelectTranslate` (Win) or `~/.selecttranslate` (Mac/Linux) |
| Python | Auto-installed if missing (Win) |
| pynput | Python package for mouse detection |
| Chrome Extension | Load unpacked or from Chrome Web Store |

## Uninstall

### Windows
Run `windows/uninstall.bat` as administrator

### macOS / Linux
```bash
./uninstall.sh
```

Then remove the extension from `chrome://extensions/`

## Troubleshooting

### "Extension not detected"
1. Make sure you installed the Chrome extension
2. Restart Chrome completely (close ALL windows)

### macOS: Selection not working
Grant Accessibility permission:
- System Preferences → Security & Privacy → Privacy → Accessibility
- Add Terminal (or your terminal app)

### Linux: Selection not working
Install required tools:
```bash
sudo apt install xdotool xclip  # Ubuntu/Debian
sudo dnf install xdotool xclip  # Fedora
sudo pacman -S xdotool xclip    # Arch
```

### Chrome not connecting
1. Restart Chrome completely (close all windows)
2. Check extension is enabled at `chrome://extensions/`
3. Make sure extension is not paused (click ▶)

## Features

- ✅ Auto-translates on text selection
- ✅ Double-click to select word
- ✅ 40+ languages supported
- ✅ Translation history with export
- ✅ Smart caching (offline translations)
- ✅ Works with Chrome & Edge
- ✅ Zero resources when paused
- ✅ Cross-platform (Windows, macOS, Linux)
