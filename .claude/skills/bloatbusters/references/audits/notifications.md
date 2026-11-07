# Audit: notification cleanup and distraction reduction

`dumpsys notification` can contain message text, titles, and contact names. Always save it to a file and extract only package/channel metadata.

## Collect

```bash
adb -s SERIAL shell dumpsys notification > SESSION/notification.txt
grep -oE "pkg=[A-Za-z0-9._]+" SESSION/notification.txt | sort | uniq -c | sort -rn | head -20   # rough volume by package
```

The count covers currently posted and recently tracked records, not a full history. If the user has Notification history enabled (Settings → Notifications → Notification history), it is the better source; ask them to look at it.

Per candidate:
```bash
adb -s SERIAL shell dumpsys package PACKAGE | grep -F "android.permission.POST_NOTIFICATIONS"   # Android 13+
grep -A 60 -F "AppSettings: PACKAGE" SESSION/notification.txt | grep -oE "mId='[^']*'|mImportance=[0-9]+" | paste - - | head -30   # channel id + importance
```

Channel dumps vary by version. If channel metadata isn't cleanly extractable, describe the app-level finding and send the user to the Settings path.

## Recommend (precise, user-approved)

- Turn off or silence a specific channel (Settings → Notifications → App notifications → APP → channel).
- Revoke notification permission for one app (Android 13+, `changes.md`).
- Keep messaging, security, authentication, health, home, work, and calendar notifications enabled unless the user specifically asks.

Never disable notifications globally or revoke permissions in bulk.

## Distraction reduction

Beyond per-app notifications, look at interruption sources and point to the user-facing controls:

```bash
adb -s SERIAL shell settings get global zen_mode    # 0 off, 1 priority only, 2 total silence, 3 alarms only
```

- Do Not Disturb / Modes: schedules, allowed people/apps (Settings → Notifications → Do Not Disturb or Modes).
- Digital Wellbeing (if present): focus mode, bedtime mode, app timers.
- Badges, lock-screen notifications, pop-up/heads-up behavior, vibration for silent channels.
- Apps with the most notifications that the user says they don't act on are the best candidates.

Configure these through Settings with the user. Do not toggle zen or Digital Wellbeing state over ADB.
