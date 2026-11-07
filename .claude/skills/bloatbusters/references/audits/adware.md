# Audit: pop-up ads and suspicious apps

Ads that appear over other apps, on the lock screen, or as full-screen pop-ups usually come from one of four places: a user-installed app that draws over other apps, a website allowed to send browser notifications, an OEM system app that shows ads, or a sideloaded app. Find which one before recommending anything.

## Establish the symptom first

Ask: where the ad appears (over other apps, on the home screen, in the notification shade, on the lock screen, in the browser), how often, and when it started (a recent install is the most common cause).

## 1. Catch the pop-up in the act (most reliable)

Ask the user to wait for the next pop-up and tell you while it is still on screen. Then run immediately:

```bash
adb -s SERIAL shell dumpsys window | grep -E "mCurrentFocus|mFocusedApp" | head -4
adb -s SERIAL shell dumpsys activity activities | grep -E "topResumedActivity|mResumedActivity" | head -3
```

The package before the `/` owns the window. If it is the app the user was using, the ad is in-app (expected for free apps). If it is some other package, that package is the culprit.

For notification ads, ask the user to long-press the notification. Android shows the app that posted it.

## 2. Browser notification spam

Websites that the user allowed to send notifications are a very common source of "virus" or "prize" alerts. Check browser volume in the notification dump (`audits/notifications.md`). If a browser such as `com.android.chrome` is at the top, the fix is in the browser, not ADB: Chrome → Settings → Site settings → Notifications, and block the unwanted sites. Other browsers have equivalent menus.

## 3. Candidates

```bash
adb -s SERIAL shell pm list packages -3 -i > SESSION/third_party.txt                 # installer for each user app
adb -s SERIAL shell cmd appops query-op SYSTEM_ALERT_WINDOW allow > SESSION/overlay.txt   # draw over other apps
adb -s SERIAL shell cmd package query-activities --brief -a android.intent.action.MAIN -c android.intent.category.LAUNCHER > SESSION/launchable.txt
```

**Hidden apps:** user-installed packages with no launcher icon. Compare `third_party.txt` with the packages in `launchable.txt` (the part before `/`) using a small local script. Many legitimate apps have no icon (keyboards, wallpapers, widgets, plugins, companion services), so this is a lead, not proof.

**Per candidate** (read-only loop over a short list):

```bash
adb -s SERIAL shell dumpsys package PACKAGE | grep -E "firstInstallTime|lastUpdateTime|installerPackageName|targetSdk" | head -5
adb -s SERIAL shell dumpsys package PACKAGE | grep -E "android.permission.[A-Z_]+: granted=true" | grep -E "SYSTEM_ALERT_WINDOW|REQUEST_INSTALL_PACKAGES|READ_SMS|RECEIVE_SMS|BIND_ACCESSIBILITY|QUERY_ALL_PACKAGES|PACKAGE_USAGE_STATS|USE_FULL_SCREEN_INTENT"
```

Also check the special access from `audits/privacy.md` (accessibility, notification listener, device admin, VPN, install unknown apps).

**Weighted signals:** recent install around when the ads started; installer is a browser, file manager, or `null` for a non-preinstalled app; overlay permission; no launcher icon; device admin; accessibility service; unusual package name not matching any app the user recognizes; generic utility type (flashlight, cleaner, QR scanner, wallpaper, VPN from an unknown publisher).

**OEM system ads:** some manufacturers show ads from system apps (Xiaomi MSA/`com.miui.msa.global`, lock-screen content services such as Glance on some Xiaomi, Samsung, and Motorola phones). Check for them with `grep -iE "msa|glance|ads" SESSION/system.txt` after `pm list packages -s > SESSION/system.txt`. Most have an in-app or Settings switch to turn off recommendations or lock-screen content. Prefer that switch, and disable the package only after approval (`changes.md`).

## 4. Play Protect

Ask the user to run Play Store → profile icon → Play Protect → **Scan**, and to make sure it is turned on. Report what it finds. Do not change Play Protect settings over ADB.

## Stalkerware caution

If the user suspects that **someone else** installed monitoring software (a partner, ex-partner, or family member), slow down before removing anything. Removing it can alert the person who installed it. Explain this, and point the user to the Coalition Against Stalkerware (stopstalkerware.org) and local support services so they can make a safety plan first. Collect read-only evidence only. Changes happen only if the user decides to go ahead.

## Recommend (each needs approval)

1. Uninstall the culprit through Settings → Apps → APP → **Uninstall**. If Uninstall is greyed out, it is a device admin: first remove it in Settings → Security → Device admin apps (path varies), then uninstall.
2. If the app fights back (re-opens, blocks the screen), boot into safe mode (`recovery.md`, Safe mode) and uninstall it there. As a reversible stopgap, `pm disable-user --user 0 PACKAGE` (`changes.md`) stops it immediately.
3. Revoke its special access (overlay, accessibility, notification listener, install unknown apps) through Settings.
4. Turn off **Install unknown apps** for the browser or file manager that installed it (`audits/privacy.md`).
5. Block spammy websites' notification permission in the browser.
6. Suggest Private DNS with an ad-blocking resolver (`audits/privacy.md`) as an optional system-wide reduction in ads.

Never uninstall user-installed apps over ADB (no rollback). Never claim an app is malware based on signals alone. Say "shows these signals", and let Play Protect or the user's judgment confirm it.
