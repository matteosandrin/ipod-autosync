-- Detect an iPod in iTunes, sync it, wait for sync completion, eject.
-- Completion is inferred when free space stops changing for several polls.

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

on freeSpaceOf(srcName)
	tell application "iTunes"
		try
			return free space of (first source whose name is srcName)
		on error
			return -1
		end try
	end tell
end freeSpaceOf

set srcName to findIpod()
if srcName is "" then return "no-ipod"

log "ipod-autosync: found iPod " & srcName
tell application "iTunes" to update (first source whose name is srcName)

-- Give the sync a chance to actually start.
delay 15

set lastFree to freeSpaceOf(srcName)
set stableCount to 0
set maxWaitMinutes to 60
set waited to 0

repeat
	delay 10
	set waited to waited + 10
	set curFree to freeSpaceOf(srcName)
	if curFree is -1 then
		-- Source vanished (already ejected or disconnected).
		return "source-gone"
	end if
	if curFree is lastFree then
		set stableCount to stableCount + 1
	else
		set stableCount to 0
	end if
	set lastFree to curFree
	-- ~60s of no change ≈ sync done
	if stableCount ≥ 6 then exit repeat
	if waited > (maxWaitMinutes * 60) then exit repeat
end repeat

try
	tell application "iTunes" to eject (first source whose name is srcName)
	return "ejected"
on error errMsg
	return "eject-failed: " & errMsg
end try
