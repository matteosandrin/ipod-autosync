-- Detect an iPod in iTunes, sync it, wait for sync completion, eject.
-- iTunes holds iPod_Control/iTunes/iTunesLock while it writes to the iPod.
-- The sync is done when the lock is gone and iTunesDB is newer than the sync start.

on findIpod()
	tell application "iTunes"
		repeat with s in sources
			try
				if (kind of s) is iPod then return (name of s) as string
			end try
		end repeat
	end tell
	return ""
end findIpod

-- Return the iPod_Control/iTunes dir of the mounted iPod, or "" if not found.
on findItunesDir(srcName)
	set candidate to "/Volumes/" & srcName & "/iPod_Control/iTunes"
	return do shell script "for d in " & quoted form of candidate & " /Volumes/*/iPod_Control/iTunes; do [ -d \"$d\" ] && { echo \"$d\"; exit 0; }; done; true"
end findItunesDir

-- Return "gone", "locked", "synced" (iTunesDB written after t0) or "idle".
-- Use the filesystem, because iTunes does not reply to Apple events during a sync.
on ipodState(dir, t0)
	return do shell script "d=" & quoted form of dir & "
[ -d \"$d\" ] || { echo gone; exit 0; }
[ -e \"$d/iTunesLock\" ] && { echo locked; exit 0; }
m=$(stat -f %m \"$d/iTunesDB\" 2>/dev/null || echo 0)
[ \"$m\" -gt " & t0 & " ] && echo synced || echo idle"
end ipodState

set srcName to findIpod()
if srcName is "" then return "no-ipod"

set itunesDir to findItunesDir(srcName)
if itunesDir is "" then return "no-volume for " & srcName

log "ipod-autosync: found iPod " & srcName & " at " & itunesDir

-- iTunes also takes the lock and writes iTunesDB right after connect.
-- Wait for that to finish, so that it is not mistaken for the end of the sync.
repeat 60 times
	set curState to ipodState(itunesDir, 0)
	if curState is "gone" then return "source-gone"
	if curState is not "locked" then exit repeat
	delay 1
end repeat

set t0 to do shell script "date +%s"
tell application "iTunes" to update (first source whose name is srcName)

-- If the lock stays released without a new iTunesDB for this long,
-- the sync had nothing to write (or did not start).
set idleLimit to 30
set maxWaitMinutes to 60
set idleCount to 0
set waited to 0

repeat
	delay 1
	set waited to waited + 1
	set curState to ipodState(itunesDir, t0)
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
	return "ejected (" & curState & " after " & waited & "s)"
on error errMsg
	return "eject-failed: " & errMsg
end try
