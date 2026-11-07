# Audit: storage cleanup

## Collect

```bash
adb -s SERIAL shell df -h /data
adb -s SERIAL shell dumpsys diskstats > SESSION/diskstats.txt
grep -nE "Data-Free|System Size|App Size|App Data Size|App Cache Size|Photos Size|Videos Size|Audio Size|Downloads Size|Other Size" SESSION/diskstats.txt
adb -s SERIAL shell 'du -sh /sdcard/* 2>/dev/null' | sort -rh | head -20                 # every top-level folder, largest first
adb -s SERIAL shell 'du -sh /sdcard/Android/media/* 2>/dev/null' | sort -rh | head -10   # app media, readable on Android 11+ (WhatsApp and Telegram media live here)
```

**Hidden space** (counts and sizes only):
```bash
adb -s SERIAL shell 'find /sdcard -name ".trashed-*" -type f 2>/dev/null | wc -l; find /sdcard -name ".trashed-*" -type f -exec du -ch {} + 2>/dev/null | tail -1'   # trashed media, deleted after ~30 days
adb -s SERIAL shell 'du -sh /sdcard/DCIM/.thumbnails /sdcard/Pictures/.thumbnails 2>/dev/null'                                                  # thumbnail caches
adb -s SERIAL shell 'find /sdcard/Download -iname "*.apk" -type f 2>/dev/null | wc -l; find /sdcard/Download -iname "*.apk" -type f -exec du -ch {} + 2>/dev/null | tail -1'   # leftover installers
adb -s SERIAL shell 'du -sh /sdcard/DCIM/Screenshots /sdcard/Pictures/Screenshots /sdcard/Movies/Screen* /sdcard/DCIM/Screen* 2>/dev/null'       # screenshots and screen recordings
```
With very many files, `-exec ... {} +` may run `du` more than once, and the last `total` line then covers only the final batch. Treat it as a lower bound.

`diskstats` includes `Package Names`, `App Sizes`, `App Data Sizes`, and `Cache Sizes` arrays in matching order. To rank apps, extract them and join by index with a small local script that only reads the saved file.

The shell user cannot read other apps' private directories (`/data/data`, and on Android 11+ most of `/sdcard/Android/data`). Do not claim complete per-app numbers. Point the user to Settings → Storage for app-by-app details.

Only list individual file names (for example `find /sdcard/Download -size +100M`) if the user asks. File names can be personal. Prefer sizes and counts.

## Prioritize

1. Large user-installed apps the user no longer needs. Archive them on Android 15+ to keep their data (`audits/unused-apps.md`).
2. Trash bins: the system trash (`.trashed-*` files), Google Photos → Library → Trash, Samsung Gallery → Recycle bin, Files by Google → Trash. Emptying trash is permanent, so the user does it in the app after checking.
3. Downloads, leftover `.apk` installers, screenshots, screen recordings, and duplicate media the user reviews themselves. Files by Google → Clean (or the OEM's "Storage" / "Device care" cleaner) finds duplicates, large files, and old screenshots safely, with a review step.
4. Media already backed up to the cloud: Google Photos → Free up space removes local copies of backed-up photos. Confirm the backup really finished first.
5. App-managed offline content (maps, music, video, podcasts), via each app's own settings.
6. Messaging attachments (WhatsApp, Telegram, Signal), via the app's built-in storage manager. `Android/media` sizes show which one is worth it.
7. App cache, only for a specific app with a specific reason, via Settings → Apps → APP → Storage → Clear cache.
8. Only if storage is still critically low after the above: system-wide cache trim (`pm trim-caches`), an approval-only, **not undoable** maintenance command (`changes.md`).

Thumbnail caches regenerate, so deleting them only frees space briefly. Mention them only if they're unusually large (several GB).

Never delete photos, messages, downloads, trash, or app data over ADB. The user deletes files in their own apps. Never use `pm clear`.
