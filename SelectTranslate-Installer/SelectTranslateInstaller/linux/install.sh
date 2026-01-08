#!/bin/bash

set -e

echo ""
echo "===================================================="
echo "  SelectTranslate - Linux Installer"
echo "===================================================="
echo ""

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

INSTALL_DIR="$HOME/.selecttranslate"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "[Step 1/4] Checking Python installation..."
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

for cmd in python3 python; do
    if check_python_version "$cmd" 2>/dev/null; then
        PYTHON_CMD="$cmd"
        break
    fi
done

if [ -z "$PYTHON_CMD" ]; then
    echo -e "${YELLOW}Python 3.8+ not found. Installing...${NC}"
    echo ""
    
    if command -v apt-get &> /dev/null; then
        sudo apt-get update
        sudo apt-get install -y python3 python3-pip python3-dev
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y python3 python3-pip python3-devel
    elif command -v yum &> /dev/null; then
        sudo yum install -y python3 python3-pip python3-devel
    elif command -v pacman &> /dev/null; then
        sudo pacman -S --noconfirm python python-pip
    elif command -v zypper &> /dev/null; then
        sudo zypper install -y python3 python3-pip
    else
        echo -e "${RED}Could not detect package manager.${NC}"
        echo "Please install Python 3.8+ manually."
        exit 1
    fi
    
    PYTHON_CMD="python3"
fi

PYTHON_VERSION=$($PYTHON_CMD --version 2>&1)
echo -e "${GREEN}Found: $PYTHON_VERSION${NC}"
echo ""

echo "[Step 2/4] Checking system dependencies..."
echo ""

MISSING_DEPS=""

if ! command -v xdotool &> /dev/null; then
    MISSING_DEPS="$MISSING_DEPS xdotool"
fi

if ! command -v xclip &> /dev/null; then
    MISSING_DEPS="$MISSING_DEPS xclip"
fi

if [ -n "$MISSING_DEPS" ]; then
    echo "Installing system dependencies:$MISSING_DEPS"
    
    if command -v apt-get &> /dev/null; then
        sudo apt-get install -y $MISSING_DEPS
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y $MISSING_DEPS
    elif command -v yum &> /dev/null; then
        sudo yum install -y $MISSING_DEPS
    elif command -v pacman &> /dev/null; then
        sudo pacman -S --noconfirm $MISSING_DEPS
    elif command -v zypper &> /dev/null; then
        sudo zypper install -y $MISSING_DEPS
    fi
fi

echo -e "${GREEN}System dependencies: OK${NC}"
echo ""

echo "[Step 3/4] Installing Python dependencies..."
echo ""

$PYTHON_CMD -m pip install --upgrade pip --quiet 2>/dev/null || true
$PYTHON_CMD -m pip install pynput --quiet --break-system-packages 2>/dev/null || \
$PYTHON_CMD -m pip install pynput --quiet 2>/dev/null || \
$PYTHON_CMD -m pip install pynput --user --quiet 2>/dev/null

if $PYTHON_CMD -c "from pynput import mouse" 2>/dev/null; then
    echo -e "${GREEN}pynput: OK${NC}"
else
    echo -e "${YELLOW}WARNING: pynput installation may have issues${NC}"
fi
echo ""

echo "[Step 4/4] Installing SelectTranslate native host..."
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

cat > "$INSTALL_DIR/run_host.sh" << EOF
#!/bin/bash
exec $PYTHON_CMD "$INSTALL_DIR/native_host.py" "\$@"
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

CHROME_DIR="$HOME/.config/google-chrome/NativeMessagingHosts"
mkdir -p "$CHROME_DIR"
echo "$MANIFEST_CONTENT" > "$CHROME_DIR/com.selecttranslate.host.json"
echo "✓ Chrome manifest installed"

CHROMIUM_DIR="$HOME/.config/chromium/NativeMessagingHosts"
mkdir -p "$CHROMIUM_DIR"
echo "$MANIFEST_CONTENT" > "$CHROMIUM_DIR/com.selecttranslate.host.json"
echo "✓ Chromium manifest installed"

EDGE_DIR="$HOME/.config/microsoft-edge/NativeMessagingHosts"
mkdir -p "$EDGE_DIR"
echo "$MANIFEST_CONTENT" > "$EDGE_DIR/com.selecttranslate.host.json"
echo "✓ Edge manifest installed"

BRAVE_DIR="$HOME/.config/BraveSoftware/Brave-Browser/NativeMessagingHosts"
mkdir -p "$BRAVE_DIR"
echo "$MANIFEST_CONTENT" > "$BRAVE_DIR/com.selecttranslate.host.json"
echo "✓ Brave manifest installed"

VIVALDI_DIR="$HOME/.config/vivaldi/NativeMessagingHosts"
mkdir -p "$VIVALDI_DIR"
echo "$MANIFEST_CONTENT" > "$VIVALDI_DIR/com.selecttranslate.host.json"
echo "✓ Vivaldi manifest installed"

echo ""
echo -e "${GREEN}===================================================="
echo "  Installation Complete!"
echo "====================================================${NC}"
echo ""
echo "Installed to: $INSTALL_DIR"
echo ""
echo "NEXT STEPS:"
echo "1. Install the Chrome extension (load unpacked)"
echo "2. Restart Chrome completely"
echo "3. Click ▶ Play to start translating!"
echo ""
echo "The extension starts PAUSED by default."
echo ""

if [ "$XDG_SESSION_TYPE" = "wayland" ]; then
    echo -e "${YELLOW}NOTE: You're running Wayland.${NC}"
    echo "Text selection from other apps may have limited support."
    echo "The extension will still work for web pages."
    echo ""
fi
