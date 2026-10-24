#!/bin/bash
# Run by launchd on each volume mount. If the iPod is mounted, sync and
# eject. Guarded by a lock so overlapping runs do not stack.

set -u

LOCK="/tmp/ipod-autosync.lock"
LOG="$HOME/Library/Logs/ipod-autosync.log"
SCRIPT="$HOME/bin/ipod-autosync.applescript"
IPOD_DIR="/Volumes/iPod/iPod_Control"

# Most mounts are not the iPod. Exit before we write to the log.
if [ ! -d "$IPOD_DIR" ]; then
	exit 0
fi

exec >>"$LOG" 2>&1

# Non-blocking lock via mkdir (atomic on macOS).
if ! mkdir "$LOCK" 2>/dev/null; then
	exit 0
fi
trap 'rmdir "$LOCK"' EXIT

# Only act when iTunes is already running; we do not want to launch it
# for every mount.
if ! pgrep -x iTunes >/dev/null; then
	exit 0
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] iPod mounted"
result=$(/usr/bin/osascript "$SCRIPT" 2>&1)
echo "[$(date '+%Y-%m-%d %H:%M:%S')] result: $result"
