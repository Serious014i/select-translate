#!/bin/bash

set -e

echo ""
echo "===================================================="
echo "  SelectTranslate - macOS Installer"
echo "===================================================="
echo ""

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

INSTALL_DIR="$HOME/.selecttranslate"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

MACOS_VERSION=$(sw_vers -productVersion)
MACOS_MAJOR=$(echo "$MACOS_VERSION" | cut -d. -f1)
echo "macOS Version: $MACOS_VERSION"
echo ""

echo "[Step 1/3] Checking Python installation..."
echo ""

PYTHON_CMD=""

check_python_version() {
    local python_path="$1"
    if command -v "$python_path" &> /dev/null; then
        version=$("$python_path" -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')" 2>/dev/null)
        major=$(echo "$version" | cut -d. -f1)
        minor=$(echo "$version" | cut -d. -f2)
        if [ "$major" = "3" ] && [ "$minor" -ge 8 ]; then
            return 0
        fi
    fi
    return 1
}

for cmd in python3 python /usr/local/bin/python3 /opt/homebrew/bin/python3 /usr/bin/python3; do
    if check_python_version "$cmd" 2>/dev/null; then
        PYTHON_CMD="$cmd"
        break
    fi
done

if [ -z "$PYTHON_CMD" ]; then
    echo -e "${YELLOW}Python 3.8+ not found.${NC}"
    echo ""
    
    if command -v brew &> /dev/null; then
        echo "Installing Python via Homebrew..."
        brew install python3
        PYTHON_CMD="python3"
    else
        echo "Please install Python 3.8+ first:"
        echo ""
        echo "  Option 1: Install Homebrew first:"
        echo "    /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        echo "    brew install python3"
        echo ""
        echo "  Option 2: Download from python.org:"
        echo "    https://www.python.org/downloads/"
        echo ""
        exit 1
    fi
fi

PYTHON_VERSION=$($PYTHON_CMD --version 2>&1)
echo -e "${GREEN}Found: $PYTHON_VERSION${NC}"
echo ""

echo "[Step 2/3] Installing Python dependencies..."
echo ""

$PYTHON_CMD -m pip install --upgrade pip --quiet 2>/dev/null || true

$PYTHON_CMD -m pip install pynput --quiet --break-system-packages 2>/dev/null || \
$PYTHON_CMD -m pip install pynput --quiet 2>/dev/null || \
$PYTHON_CMD -m pip install pynput --user --quiet 2>/dev/null || \
pip3 install pynput --user --quiet 2>/dev/null

if $PYTHON_CMD -c "from pynput import mouse" 2>/dev/null; then
    echo -e "${GREEN}pynput: OK${NC}"
else
    echo -e "${YELLOW}WARNING: pynput installation may have issues${NC}"
    echo "Try manually: pip3 install pynput"
fi
echo ""

echo "[Step 3/3] Installing SelectTranslate native host..."
echo ""

mkdir -p "$INSTALL_DIR"

if [ -f "$SCRIPT_DIR/native_host.py" ]; then
    cp "$SCRIPT_DIR/native_host.py" "$INSTALL_DIR/native_host.py"
elif [ -f "$SCRIPT_DIR/../windows/native_host.py" ]; then
    cp "$SCRIPT_DIR/../windows/native_host.py" "$INSTALL_DIR/native_host.py"
else
    echo -e "${RED}ERROR: native_host.py not found${NC}"
    exit 1
fi
chmod +x "$INSTALL_DIR/native_host.py"

PYTHON_FULL_PATH=$($PYTHON_CMD -c "import sys; print(sys.executable)")

cat > "$INSTALL_DIR/run_host.sh" << EOF
#!/bin/bash
exec "$PYTHON_FULL_PATH" "$INSTALL_DIR/native_host.py" "\$@"
EOF
chmod +x "$INSTALL_DIR/run_host.sh"

MANIFEST_CONTENT='{
  "name": "com.selecttranslate.host",
  "description": "SelectTranslate Native Host",
  "path": "'"$INSTALL_DIR/run_host.sh"'",
  "type": "stdio",
  "allowed_origins": [
    "chrome-extension://*/",
    "chrome-extension://*/*"
  ]
}'

CHROME_DIR="$HOME/Library/Application Support/Google/Chrome/NativeMessagingHosts"
mkdir -p "$CHROME_DIR"
echo "$MANIFEST_CONTENT" > "$CHROME_DIR/com.selecttranslate.host.json"
echo "✓ Chrome manifest installed"

CANARY_DIR="$HOME/Library/Application Support/Google/Chrome Canary/NativeMessagingHosts"
mkdir -p "$CANARY_DIR"
echo "$MANIFEST_CONTENT" > "$CANARY_DIR/com.selecttranslate.host.json"
echo "✓ Chrome Canary manifest installed"

CHROMIUM_DIR="$HOME/Library/Application Support/Chromium/NativeMessagingHosts"
mkdir -p "$CHROMIUM_DIR"
echo "$MANIFEST_CONTENT" > "$CHROMIUM_DIR/com.selecttranslate.host.json"
echo "✓ Chromium manifest installed"

EDGE_DIR="$HOME/Library/Application Support/Microsoft Edge/NativeMessagingHosts"
mkdir -p "$EDGE_DIR"
echo "$MANIFEST_CONTENT" > "$EDGE_DIR/com.selecttranslate.host.json"
echo "✓ Edge manifest installed"

BRAVE_DIR="$HOME/Library/Application Support/BraveSoftware/Brave-Browser/NativeMessagingHosts"
mkdir -p "$BRAVE_DIR"
echo "$MANIFEST_CONTENT" > "$BRAVE_DIR/com.selecttranslate.host.json"
echo "✓ Brave manifest installed"

ARC_DIR="$HOME/Library/Application Support/Arc/User Data/NativeMessagingHosts"
mkdir -p "$ARC_DIR"
echo "$MANIFEST_CONTENT" > "$ARC_DIR/com.selecttranslate.host.json"
echo "✓ Arc manifest installed"

echo ""
echo -e "${GREEN}===================================================="
echo "  Installation Complete!"
echo "====================================================${NC}"
echo ""
echo "Installed to: $INSTALL_DIR"
echo ""

echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  IMPORTANT: Grant Accessibility Permission"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if [ "$MACOS_MAJOR" -ge 15 ]; then
    echo -e "${BLUE}For macOS Tahoe (15+):${NC}"
    echo ""
    echo "1. Open System Settings → Privacy & Security → Accessibility"
    echo ""
    echo "2. Click '+' to add these applications:"
    echo "   - Your browser (Chrome, Edge, Arc, etc.)"
    echo "   - Terminal (or iTerm2 if you use it)"
    echo ""
    echo "3. If prompted, enter your password"
    echo ""
    echo "4. You may need to RESTART your browser after granting permission"
    echo ""
    echo -e "${YELLOW}Note: macOS Tahoe requires the BROWSER to have accessibility"
    echo "permission, not just Terminal.${NC}"
else
    echo -e "${BLUE}For macOS Sonoma (14) and earlier:${NC}"
    echo ""
    echo "1. Open System Preferences → Security & Privacy → Privacy"
    echo ""
    echo "2. Select 'Accessibility' in the left panel"
    echo ""
    echo "3. Click the lock icon to make changes"
    echo ""
    echo "4. Click '+' and add:"
    echo "   - Terminal (or your terminal app)"
    echo "   - Your browser (Chrome, Edge, etc.)"
    echo ""
fi

echo ""
echo "Would you like to open System Settings now? (y/n)"
read -r response
if [[ "$response" =~ ^[Yy]$ ]]; then
    if [ "$MACOS_MAJOR" -ge 13 ]; then
        open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
    else
        open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
    fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "NEXT STEPS:"
echo "1. Grant Accessibility permission (see above)"
echo "2. Install the Chrome extension (load unpacked)"
echo "3. Restart your browser completely"
echo "4. Click ▶ Play to start translating!"
echo ""
echo "The extension starts PAUSED by default."
echo ""

echo "Testing accessibility permission..."
if $PYTHON_CMD -c "
from pynput import mouse
import time
def on_click(x, y, button, pressed):
    return False
try:
    listener = mouse.Listener(on_click=on_click)
    listener.start()
    time.sleep(0.5)
    listener.stop()
    print('OK')
except Exception as e:
    print(f'FAIL: {e}')
" 2>/dev/null | grep -q "OK"; then
    echo -e "${GREEN}✓ Accessibility permission appears to be granted${NC}"
else
    echo -e "${YELLOW}⚠ Accessibility permission may not be granted yet${NC}"
    echo "  Please follow the instructions above to grant permission."
fi
echo ""

