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

CHROME_MANIFEST="$HOME/.config/google-chrome/NativeMessagingHosts/com.selecttranslate.host.json"
if [ -f "$CHROME_MANIFEST" ]; then
    rm -f "$CHROME_MANIFEST"
    echo "✓ Removed Chrome manifest"
fi

CHROMIUM_MANIFEST="$HOME/.config/chromium/NativeMessagingHosts/com.selecttranslate.host.json"
if [ -f "$CHROMIUM_MANIFEST" ]; then
    rm -f "$CHROMIUM_MANIFEST"
    echo "✓ Removed Chromium manifest"
fi

EDGE_MANIFEST="$HOME/.config/microsoft-edge/NativeMessagingHosts/com.selecttranslate.host.json"
if [ -f "$EDGE_MANIFEST" ]; then
    rm -f "$EDGE_MANIFEST"
    echo "✓ Removed Edge manifest"
fi

BRAVE_MANIFEST="$HOME/.config/BraveSoftware/Brave-Browser/NativeMessagingHosts/com.selecttranslate.host.json"
if [ -f "$BRAVE_MANIFEST" ]; then
    rm -f "$BRAVE_MANIFEST"
    echo "✓ Removed Brave manifest"
fi

VIVALDI_MANIFEST="$HOME/.config/vivaldi/NativeMessagingHosts/com.selecttranslate.host.json"
if [ -f "$VIVALDI_MANIFEST" ]; then
    rm -f "$VIVALDI_MANIFEST"
    echo "✓ Removed Vivaldi manifest"
fi

echo ""
echo "Uninstall complete!"
echo ""
echo "Don't forget to remove the Chrome extension from chrome://extensions/"
echo ""
