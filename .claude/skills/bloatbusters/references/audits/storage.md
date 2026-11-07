# Audit: storage cleanup

## Collect

```bash
adb -s SERIAL shell df -h /data
adb -s SERIAL shell dumpsys diskstats > SESSION/diskstats.txt
grep -nE "Data-Free|System Size|App Size|App Data Size|App Cache Size|Photos Size|Videos Size|Audio Size|Downloads Size|Other Size" SESSION/diskstats.txt
adb -s SERIAL shell 'du -sh /sdcard/Download /sdcard/DCIM /sdcard/Pictures /sdcard/Movies /sdcard/Music /sdcard/Documents 2>/dev/null'
```

`diskstats` includes `Package Names`, `App Sizes`, `App Data Sizes`, and `Cache Sizes` arrays in matching order. To rank apps, extract them and join by index with a small local script that only reads the saved file.

The shell user cannot read other apps' private directories (`/data/data`, and on Android 11+ most of `/sdcard/Android/data`). Do not claim complete per-app numbers. Point the user to Settings → Storage for app-by-app details.

Only list individual file names (for example `find /sdcard/Download -size +100M`) if the user asks. File names can be personal. Prefer sizes and counts.

## Prioritize

1. Large user-installed apps the user no longer needs.
2. Downloads and duplicate media the user reviews themselves.
3. App-managed offline content (maps, music, video, podcasts), via each app's own settings.
4. Messaging attachments, via the app's built-in storage manager.
5. App cache, only for a specific app with a specific reason, via Settings → Apps → APP → Storage → Clear cache.

Never delete photos, messages, downloads, or app data automatically. Never use `pm clear`.
