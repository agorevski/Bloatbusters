# Back up the phone (optional) and full restore

Offered as its own goal, and once before the first change of a session ("Want a local backup before I change anything?"). Never required, never automatic. Backing up only reads from the phone, but it writes potentially many GB of personal data to the computer, so the user chooses where and what.

## 1. Ask where and what

Ask for a destination directory, then check it:

```bash
df -h "DEST"                                              # free space on the computer
git -C "DEST" rev-parse --is-inside-work-tree 2>/dev/null # must NOT print "true"
fdesetup status 2>/dev/null                               # macOS: is FileVault on?
```

- Refuse a destination inside a git repository (including this one), where photos could be committed by accident.
- If the path is inside a cloud-sync folder (iCloud Drive, Dropbox, Google Drive, OneDrive), point out that the backup will be uploaded, and confirm.
- Recommend an encrypted disk. Mention it if FileVault/BitLocker/LUKS appears to be off.

Then ask which parts to include:

| Part | Contents | Typical size |
|---|---|---|
| **Device snapshot** (always included) | Build info, package lists and states, settings dumps | < 5 MB |
| **Media and files** | Shared storage: DCIM, Pictures, Movies, Music, Download, Documents, Recordings, other top-level folders | often 10–200 GB |
| **App installers** | APKs of user-installed apps | 1–10 GB |

Estimate the phone side and compare it with host free space (keep about 10% headroom):

```bash
adb -s SERIAL shell 'ls -1 /sdcard/'
adb -s SERIAL shell 'du -sh /sdcard/* 2>/dev/null'
```

## 2. Create the backup directory

```bash
mkdir -p -m 700 "DEST/bloatbusters-backup-RO_SERIALNO-$(date +%Y%m%d-%H%M%S)"
```

Call it `BK` below. Write `BK/MANIFEST.md` as you go: date, device model/build, `ro.serialno`, parts included, per-folder file counts and sizes, what was skipped and why, and the "not backed up" list from §5.

## 3. Collect

**Device snapshot** (contains device identifiers and settings; keep it local):
```bash
mkdir -m 700 BK/snapshot
adb -s SERIAL shell 'for p in ro.product.manufacturer ro.product.model ro.build.version.release ro.build.version.sdk ro.build.fingerprint ro.serialno; do echo "$p=$(getprop $p)"; done' > BK/snapshot/device.txt
adb -s SERIAL shell pm list packages -f -i -U > BK/snapshot/packages_all.txt
adb -s SERIAL shell pm list packages -d > BK/snapshot/packages_disabled.txt
adb -s SERIAL shell pm list packages -u > BK/snapshot/packages_including_uninstalled.txt
adb -s SERIAL shell pm list packages -3 > BK/snapshot/packages_third_party.txt
for ns in system secure global; do adb -s SERIAL shell settings list $ns > BK/snapshot/settings_$ns.txt; done
adb -s SERIAL shell pm list users > BK/snapshot/users.txt
cp ~/.bloatbusters/RO_SERIALNO/changes.jsonl ~/.bloatbusters/RO_SERIALNO/undo-steps.txt ~/.bloatbusters/RO_SERIALNO/metrics.jsonl BK/snapshot/ 2>/dev/null
```

**Media and files**: one top-level folder at a time, skipping `Android` (app-private, mostly inaccessible on Android 11+). `Android/media` is readable and holds messaging-app media (for example WhatsApp images and voice notes). Offer it as a separate item. It can be large, and the app's own backup is the better way to restore chats. Large pulls take a while, so run them in the background and report progress per folder:
```bash
mkdir -p BK/sdcard
adb -s SERIAL pull -a /sdcard/DCIM BK/sdcard/
```
Verify each folder by file count:
```bash
adb -s SERIAL shell 'find /sdcard/DCIM -type f | wc -l'
find BK/sdcard/DCIM -type f | wc -l
```
If counts differ, re-pull only that folder and report any files that still fail. Do not list personal file names in the conversation unless the user asks.

**App installers** (user-installed apps only):
```bash
adb -s SERIAL shell pm path PACKAGE           # one line per APK split
mkdir -p BK/apks/PACKAGE
adb -s SERIAL pull /data/app/.../base.apk BK/apks/PACKAGE/   # repeat for each split path
```
APKs restore the app, not its data or logins. Paid or licensed apps may still need the store. Apps from the Play Store can usually just be reinstalled from there.

## 4. Restore

Restore is a set of approved, individual steps, in this order:

1. **Reverse Bloatbusters changes:** run `~/.bloatbusters/RO_SERIALNO/undo.sh` (see `undo.md`).
2. **Compare package state:** diff `BK/snapshot/packages_disabled.txt` and `packages_all.txt` against the current lists. Show differences. Restore only items the user approves, using the commands and logging from `changes.md`. Some differences will be OS updates or the user's own choices.
3. **Reinstall apps:** per approved app, `adb -s SERIAL install-multiple -r BK/apks/PACKAGE/*.apk` (or `adb install -r` for a single APK). A signature mismatch or downgrade fails by design; use the store instead.
4. **Restore media:** per approved folder, `adb -s SERIAL push BK/sdcard/DCIM /sdcard/`. Push adds and overwrites same-named files; it never deletes. Warn about overwrites first. Gallery apps may take a while (or a reboot) to show restored media.
5. **Settings:** never bulk-restore from `settings_*.txt` (it would be a broad `settings put` loop). Use the dumps only to restore specific keys the user names, through the `changes.md` procedure.

After a factory reset, have the user finish Android setup (including Google/OEM cloud restore) and re-enable USB debugging before steps 3–4.

## 5. Tell the user what ADB cannot back up

Without root, these are **not** in a Bloatbusters backup. Recommend the official tool for each:

- App private data and logins (`adb backup` is deprecated and ignored by most apps on Android 12+) → Google One backup / Samsung Smart Switch / OEM backup.
- SMS, MMS, and call history → Google One backup or the messaging app's backup.
- Contacts → sync to the account, or export a `.vcf` from the Contacts app.
- WhatsApp, Signal, and other chat apps → each app's own backup.
- **Authenticator / 2FA codes** → the authenticator's export or cloud sync. Losing these can lock the user out of accounts, so call this out explicitly.
- Wi-Fi passwords, eSIMs, wallet cards, and biometrics → re-add after a reset.
- Work profile, Samsung Secure Folder, and Dual Apps data → only user 0's shared storage is backed up. Use the employer's process or Samsung's Secure Folder backup.
