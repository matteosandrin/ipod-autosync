#!/bin/bash
# Poll iTunes for an iPod; if present, sync and eject. Guarded by a lock
# so overlapping launchd ticks do not stack.

set -u

LOCK="/tmp/ipod-autosync.lock"
LOG="$HOME/Library/Logs/ipod-autosync.log"
SCRIPT="$HOME/bin/ipod-autosync.applescript"

exec >>"$LOG" 2>&1

# Non-blocking lock via mkdir (atomic on macOS).
if ! mkdir "$LOCK" 2>/dev/null; then
	exit 0
fi
trap 'rmdir "$LOCK"' EXIT

# Only act when iTunes is already running; otherwise, no iPod can be mounted
# in iTunes anyway, and we do not want to launch it on every poll.
if ! pgrep -x iTunes >/dev/null; then
	exit 0
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] tick"
result=$(/usr/bin/osascript "$SCRIPT" 2>&1)
echo "[$(date '+%Y-%m-%d %H:%M:%S')] result: $result"
