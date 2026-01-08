#!/bin/bash

echo ""
echo "===================================================="
echo "  SelectTranslate - Uninstaller"
echo "===================================================="
echo ""

INSTALL_DIR="$HOME/.selecttranslate"

if [ -d "$INSTALL_DIR" ]; then
    rm -rf "$INSTALL_DIR"
    echo "✓ Removed: $INSTALL_DIR"
fi

CHROME_MANIFEST="$HOME/Library/Application Support/Google/Chrome/NativeMessagingHosts/com.selecttranslate.host.json"
if [ -f "$CHROME_MANIFEST" ]; then
    rm -f "$CHROME_MANIFEST"
    echo "✓ Removed Chrome manifest"
fi

CANARY_MANIFEST="$HOME/Library/Application Support/Google/Chrome Canary/NativeMessagingHosts/com.selecttranslate.host.json"
if [ -f "$CANARY_MANIFEST" ]; then
    rm -f "$CANARY_MANIFEST"
    echo "✓ Removed Chrome Canary manifest"
fi

CHROMIUM_MANIFEST="$HOME/Library/Application Support/Chromium/NativeMessagingHosts/com.selecttranslate.host.json"
if [ -f "$CHROMIUM_MANIFEST" ]; then
    rm -f "$CHROMIUM_MANIFEST"
    echo "✓ Removed Chromium manifest"
fi

EDGE_MANIFEST="$HOME/Library/Application Support/Microsoft Edge/NativeMessagingHosts/com.selecttranslate.host.json"
if [ -f "$EDGE_MANIFEST" ]; then
    rm -f "$EDGE_MANIFEST"
    echo "✓ Removed Edge manifest"
fi

BRAVE_MANIFEST="$HOME/Library/Application Support/BraveSoftware/Brave-Browser/NativeMessagingHosts/com.selecttranslate.host.json"
if [ -f "$BRAVE_MANIFEST" ]; then
    rm -f "$BRAVE_MANIFEST"
    echo "✓ Removed Brave manifest"
fi

echo ""
echo "Uninstall complete!"
echo ""
echo "Don't forget to remove the Chrome extension from chrome://extensions/"
echo ""
