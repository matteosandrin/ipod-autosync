#!/bin/bash
# Install the ipod-autosync launchd agent for the current user.
set -euo pipefail

SRC_DIR="$(cd "$(dirname "$0")" && pwd)"
BIN_DIR="$HOME/bin"
AGENTS_DIR="$HOME/Library/LaunchAgents"
PLIST="com.matteo.ipod-autosync.plist"

mkdir -p "$BIN_DIR" "$AGENTS_DIR" "$HOME/Library/Logs"

install -m 0755 "$SRC_DIR/ipod-autosync.sh" "$BIN_DIR/ipod-autosync.sh"
install -m 0644 "$SRC_DIR/ipod-autosync.applescript" "$BIN_DIR/ipod-autosync.applescript"
install -m 0644 "$SRC_DIR/$PLIST" "$AGENTS_DIR/$PLIST"

launchctl unload "$AGENTS_DIR/$PLIST" 2>/dev/null || true
launchctl load "$AGENTS_DIR/$PLIST"

echo "Installed. Status:"
launchctl list | grep ipod-autosync || echo "(not listed — check Console for errors)"
echo
echo "Tail the log with: tail -f ~/Library/Logs/ipod-autosync.log"
echo "Note: on first run, approve the Automation prompt for iTunes."
