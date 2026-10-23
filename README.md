# ipod-autosync

Auto-syncs an iPod with iTunes when connected, then ejects it when done.
Targets macOS Mojave (10.14) with iTunes 12.

## Files

- `ipod-autosync.applescript` — finds an iPod source in iTunes, triggers
  `update`, polls `free space` until it is stable (~60s), then `eject`.
- `ipod-autosync.sh` — launchd entry point. Takes a lock so overlapping
  ticks do not stack. Skips when iTunes is not already running.
- `com.matteo.ipod-autosync.plist` — launchd agent, polls every 20s and
  runs at login.

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

Plug in the iPod with iTunes running. Expect `found iPod <name>` and
eventually `ejected`.

## Tuning

- To let the agent auto-launch iTunes on connect, remove the
  `pgrep -x iTunes` guard in `ipod-autosync.sh`.
- Sync completion is inferred when free space stops changing for six
  consecutive 10s polls. Adjust `stableCount` or `delay` in the
  AppleScript to change sensitivity.
