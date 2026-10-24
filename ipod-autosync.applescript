-- Detect an iPod in iTunes, sync it, wait for sync completion, eject.
-- iTunes holds iPod_Control/iTunes/iTunesLock while it writes to the iPod.
-- The sync is done when the lock is gone and iTunesDB is newer than the sync start.

-- Return the name of the iPod source, or "" if iTunes does not show one (or is
-- still loading and does not reply).
on findIpod()
	try
		with timeout of 5 seconds
			tell application "iTunes"
				repeat with s in sources
					try
						if (kind of s) is iPod then return (name of s) as string
					end try
				end repeat
			end tell
		end timeout
	end try
	return ""
end findIpod

-- Return "gone", "locked", "synced" (iTunesDB written after t0) or "idle".
-- Use the filesystem, because iTunes does not reply to Apple events during a sync.
on ipodState(dir, t0)
	return do shell script "d=" & quoted form of dir & "
[ -d \"$d\" ] || { echo gone; exit 0; }
[ -e \"$d/iTunesLock\" ] && { echo locked; exit 0; }
m=$(stat -f %m \"$d/iTunesDB\" 2>/dev/null || echo 0)
[ \"$m\" -gt " & t0 & " ] && echo synced || echo idle"
end ipodState

-- Append a timestamped line to the agent log, with the iTunesDB mtime.
on logLine(msg)
	do shell script "db=$(stat -f %Sm -t %T /Volumes/iPod/iPod_Control/iTunes/iTunesDB 2>/dev/null || echo none)
echo \"[$(date '+%Y-%m-%d %H:%M:%S')]   \"" & quoted form of msg & "\" (iTunesDB $db)\" >> \"$HOME/Library/Logs/ipod-autosync.log\""
end logLine

set itunesDir to "/Volumes/iPod/iPod_Control/iTunes"

-- launchd starts us on mount, a few seconds before iTunes shows the iPod.
-- If iTunes is not open, start it and allow more time for it to load.
set findLimit to 30
if application "iTunes" is not running then
	logLine("starting iTunes")
	do shell script "open -a iTunes"
	set findLimit to 120
end if

set srcName to ""
repeat findLimit times
	set srcName to findIpod()
	if srcName is not "" then exit repeat
	delay 1
end repeat
if srcName is "" then return "no-ipod in iTunes"
logLine("found " & srcName & " in iTunes")

-- Give the user 5s to cancel. If nobody clicks, the dialog gives up and we continue.
try
	activate
	display dialog "Syncing and ejecting " & srcName & " in 5 seconds." with title "iPod Autosync" buttons {"Cancel", "Sync Now"} default button "Sync Now" cancel button "Cancel" giving up after 5
on error number -128
	logLine("cancelled by user")
	return "cancelled by user"
end try

-- iTunes also takes the lock and writes iTunesDB right after connect.
-- Wait for that to finish, so that it is not mistaken for the end of the sync.
set connectWait to 0
repeat 60 times
	set curState to ipodState(itunesDir, 0)
	if curState is "gone" then return "source-gone"
	if curState is not "locked" then exit repeat
	delay 1
	set connectWait to connectWait + 1
end repeat
logLine("connect lock wait done after " & connectWait & "s, state " & curState)

set t0 to do shell script "date +%s"
logLine("sending update")
tell application "iTunes" to update (first source whose name is srcName)
logLine("update returned")

-- If the lock stays released without a new iTunesDB for this long,
-- the sync had nothing to write (or did not start).
set idleLimit to 30
set maxWaitMinutes to 60
set idleCount to 0
set waited to 0
set lastState to ""

repeat
	delay 1
	set waited to waited + 1
	set curState to ipodState(itunesDir, t0)
	if curState is not lastState then
		logLine("state " & curState & " after " & waited & "s")
		set lastState to curState
	end if
	if curState is "gone" then return "source-gone"
	if curState is "synced" then exit repeat
	if curState is "locked" then
		set idleCount to 0
	else
		set idleCount to idleCount + 1
		if idleCount ≥ idleLimit then exit repeat
	end if
	if waited > (maxWaitMinutes * 60) then exit repeat
end repeat

try
	tell application "iTunes" to eject (first source whose name is srcName)
	return "ejected " & srcName & " (" & curState & " after " & waited & "s)"
on error errMsg
	return "eject-failed: " & errMsg
end try
