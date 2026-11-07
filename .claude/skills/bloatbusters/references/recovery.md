# Recovery: something broke after a change

Use this when the phone misbehaves after a Bloatbusters change: the home screen or keyboard is missing, System UI keeps crashing, an important feature stopped working, the phone reboots repeatedly, or it shows a recovery screen.

## Prevent it

- Apply one change at a time and verify it before starting the next (`changes.md`).
- Keep the phone **connected, unlocked, and USB debugging authorized** until the session's changes are verified. ADB is the recovery path, and it keeps working even when the home screen or System UI is broken.
- Do not turn off USB debugging at the end of a session until the user has used the phone normally for a bit (SKILL.md §4, wrap-up).

## Triage

| Symptom | First step |
|---|---|
| A feature broke, phone otherwise fine | Find the most recent related change in `changes.jsonl` and run just its rollback from `undo-steps.txt` (`undo.md`, guided undo) |
| No home screen, no keyboard, or System UI crash loop, but `adb devices -l` shows `device` | Run the rollback for the most recent change now. If the cause isn't clear, run `~/.bloatbusters/RO_SERIALNO/undo.sh` for everything |
| Phone reboots repeatedly | Run `adb -s SERIAL wait-for-device` while it boots, then run `undo.sh` as soon as the device shows as `device`. adbd usually starts before the home screen |
| "Android Recovery" / "Can't load Android system" screen with **Try again** and **Factory data reset** | See [Rescue Party](#rescue-party) |
| ADB shows `unauthorized` or nothing | See [No ADB access](#no-adb-access) |

After each rollback, verify as in `changes.md` and log a `restore` entry. Tell the user what was reversed.

## Rescue Party

When core system components crash repeatedly, Android's Rescue Party first resets some settings on its own. If crashes continue, it boots into recovery and offers a factory reset.

- Tell the user to choose **Try again** (or **Reboot system now**). **Never choose Factory data reset.** It erases the phone.
- When the phone boots, connect immediately and run `undo.sh`. Bloatbusters' undo steps still apply.
- Rescue Party may have reset some settings already. After undo, compare the current `settings list` output with any earlier backup snapshot (`backup.md`), and restore only the keys the user names.
- Recovery mode has no normal ADB shell. Do not attempt `adb sideload` or any recovery-menu option other than rebooting.

## Safe mode

If a third-party app is the problem (for example adware that blocks the screen), safe mode starts Android with all user-installed apps turned off. Typically: hold Power, then long-press **Power off** and accept **Reboot to safe mode**. The method varies by OEM. Restarting normally exits safe mode.

System packages that Bloatbusters disabled stay disabled in safe mode, so safe mode does not fix Bloatbusters changes. Use ADB for those.

## No ADB access

If the phone no longer accepts ADB and the UI is too broken to re-enable it:

1. Try another cable and port, `adb kill-server`, and reconnect (`setup.md`). Wireless debugging needs the UI, so prefer USB.
2. If the phone still asks for authorization and the prompt can be seen, accept it.
3. If neither works, Bloatbusters cannot repair the phone. Factory reset is the user's decision, not yours. Do not suggest it as a casual fix. Point to the official recovery path (the OEM support page or the Android Flash Tool for Pixel) and to `backup.md` §5 for what a reset loses.

## After recovery

- Record what happened in `changes.jsonl`: a `"type":"restore"` entry whose `reason` starts with `recovery:` and names the symptom (for example `"recovery: launcher crash after disable"`).
- Treat that target as protected for the rest of the session and in later sessions. SKILL.md §3 reads `recovery:` entries back. Tell the user it should not be changed on this phone.
