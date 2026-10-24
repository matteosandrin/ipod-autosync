# ipod-autosync

Auto-syncs an iPod with iTunes when connected, then ejects it when done.
Targets macOS Mojave (10.14) with iTunes 12.

## Files

- `ipod-autosync.applescript` — finds an iPod source in iTunes, shows a
  5s dialog that lets you cancel, triggers `update`, waits for the sync
  to finish on the iPod filesystem, then `eject`.
- `ipod-autosync.sh` — launchd entry point. Exits unless the volume
  `/Volumes/iPod` is mounted. Takes a lock so overlapping runs do not
  stack. Skips when iTunes is not already running.
- `com.matteo.ipod-autosync.plist` — launchd agent, runs on every volume
  mount (`StartOnMount`) and at login.

## Install

```sh
./install.sh
```

On the first iPod connect, approve the Automation permission prompt for
`osascript` controlling iTunes (System Preferences → Security & Privacy →
Privacy → Automation).

## Uninstall

```sh
./uninstall.sh
```

## Verify

```sh
tail -f ~/Library/Logs/ipod-autosync.log
```

Plug in the iPod with iTunes running. Expect `iPod mounted` and
eventually `result: ejected <name> (synced after <n>s)`.

If iTunes is not running when the iPod mounts, nothing happens. Open
iTunes, then eject and re-plug the iPod.

## Tuning

- To let the agent auto-launch iTunes on connect, remove the
  `pgrep -x iTunes` guard in `ipod-autosync.sh`.
- iTunes holds `iPod_Control/iTunes/iTunesLock` while it writes to the
  iPod, and rewrites `iTunesDB` at the end of a sync. The sync is done
  when the lock is gone and `iTunesDB` is newer than the `update` call.
  The script polls these files every second, because iTunes does not
  reply to Apple events during a sync.
- If the lock stays released for `idleLimit` seconds (30) without a new
  `iTunesDB`, the sync is treated as a no-op and the iPod is ejected.
