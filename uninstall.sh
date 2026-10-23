#!/bin/bash
# Remove the ipod-autosync launchd agent and installed files.
set -u

AGENTS_DIR="$HOME/Library/LaunchAgents"
BIN_DIR="$HOME/bin"
PLIST="com.matteo.ipod-autosync.plist"

launchctl unload "$AGENTS_DIR/$PLIST" 2>/dev/null || true
rm -f "$AGENTS_DIR/$PLIST"
rm -f "$BIN_DIR/ipod-autosync.sh"
rm -f "$BIN_DIR/ipod-autosync.applescript"
rm -rf /tmp/ipod-autosync.lock

echo "Uninstalled. Logs left in ~/Library/Logs/ipod-autosync*.log (remove manually if desired)."
