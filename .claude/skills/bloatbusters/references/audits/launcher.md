# Audit: home screen and launcher

Use this when the home screen feels slow (blank or redrawing icons after pressing Home, lag opening the app drawer), when the user wants a simpler or less distracting home screen, or when they ask about a different launcher. A new launcher is the last step here, not the first.

## 1. Is the launcher actually the problem?

```bash
adb -s SERIAL shell cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME   # current home activity
adb -s SERIAL shell cmd package query-activities --brief -a android.intent.action.MAIN -c android.intent.category.HOME   # every installed launcher
adb -s SERIAL shell cmd role get-role-holders --user 0 android.app.role.HOME                                               # Android 10+
adb -s SERIAL shell 'getprop ro.config.low_ram; cat /proc/meminfo | head -3'
adb -s SERIAL shell dumpsys meminfo LAUNCHER_PACKAGE | grep -E "TOTAL( PSS)?:" | head -2
adb -s SERIAL logcat -d -b events -t 5000 | grep -E "am_kill|am_proc_died" | grep -cF "LAUNCHER_PACKAGE"   # launcher killed recently
adb -s SERIAL shell dumpsys gfxinfo LAUNCHER_PACKAGE | grep -E "Total frames rendered|Janky frames"         # after the user swipes around the home screen
```

`com.android.settings/.FallbackHome` is the system's boot-time placeholder, not a launcher. Ignore it.

| Signal | What it means |
|---|---|
| Launcher killed several times in the window, icons redraw after Home | Real memory pressure hitting the launcher. A lighter launcher can help, and so can fewer widgets and a static wallpaper (`audits/memory.md`) |
| High janky-frame percentage on the home screen only | Widgets, live wallpaper, or the feed page. Try §2 first |
| `ro.config.low_ram=true` or 3 GB RAM or less | Low-end device (Android Go, older Galaxy Tab A). The most likely case where a lighter launcher is a visible win |
| None of the above | The launcher isn't the bottleneck. Say so. A new launcher will mostly change looks, not speed |

## 2. Try these first (Settings only, no new app)

- **Animation scales** to `0.5` (`changes.md` settings table). This is the single biggest "feels faster" change.
- **Turn off the feed page** left of the home screen: Pixel: long-press home → Home settings → Swipe to access Google app (or Discover). Samsung: long-press home → swipe right → turn off Samsung Free / Google Discover. Other OEMs have a similar switch in home-screen settings.
- **Remove heavy widgets** (news, weather with animations, photo carousels) and use a **static wallpaper** instead of a live one.
- **Samsung:** the Good Lock "Home Up" module customizes One UI Home (grid, drawer, Recents) without replacing it.
- **App drawer clutter:** removing unused apps (`audits/unused-apps.md`) helps more than switching launchers.

## 3. Choosing a different launcher

Only proceed if §1 showed a real problem, or the user wants a different home screen for its own sake (minimal, distraction-free, simpler for someone else). Recommend only maintained launchers from a known source. As of late 2026:

| Launcher | Package | Style | Get it from | Notes |
|---|---|---|---|---|
| KISS | `fr.neamar.kiss` | Search-first, no icon grid, very small | Play Store, F-Droid | Lightest option. Best for low-RAM phones and adults who type to launch apps. Open source (GPL-3.0) |
| Olauncher | `app.olauncher` | Minimal text list, no icons | Play Store, F-Droid | Built for distraction reduction (goal 11). Good for adults and teens, not for pre-readers. Open source |
| Fossify Launcher | `org.fossify.home` | Traditional icon grid and drawer | F-Droid, GitHub (FossifyOrg/Launcher) | Light, no Internet permission, familiar layout. Still labeled beta. Open source |
| Lawnchair | `app.lawnchair.play` (Play; GitHub builds use a different ID) | Pixel-style Launcher3 | Play Store, GitHub (LawnchairLauncher) | Smooth, feature-rich, imports Nova backups. Lawnchair 15 is still beta, and the 16 branch is nightly-only. Heavier than the others, so not the pick for low-RAM devices |

Before recommending one, check its store page or release page for a release within the last 6 months and support for the phone's Android version. If that fails, say so and pick another.

Do **not** recommend:

- **Nova Launcher.** Development ended in 2025, and since its January 2026 sale to Instabridge its builds include ad and tracking SDKs. Users who have it can keep it, but don't install it fresh.
- "Fast", "booster", "battery saver", or "kids" launchers from unknown publishers. They are a common adware and data-collection vector (`audits/adware.md`). A launcher sees every app the user opens.
- APK mirror sites (APKMirror, APKPure, and similar) as the source. Use the Play Store, F-Droid, or the project's own GitHub releases.

Don't build a custom launcher for this. The open-source options above already cover light, minimal, and traditional layouts, and a homegrown launcher would need ongoing fixes for every Android release.

**For a child's device**, a third-party launcher is not a lock. A child can switch back in Settings or install another one. Use the built-in kids modes instead (`audits/kids.md`): Samsung Kids, Google Kids Space on supported tablets, or Family Link.

## 4. Known trade-offs to tell the user

- **Recents and gestures still come from the stock launcher** on Android 10+. With a third-party launcher, gesture animations can be less smooth, and some OEM builds limit gesture navigation with third-party launchers (falling back to 3-button navigation). Test it before committing.
- **Never disable or uninstall the stock launcher**, even after switching. It provides Recents, and it is what Android falls back to if the new launcher crashes. It stays on the protected list.
- Some home-screen features are tied to the stock launcher: the Pixel "At a glance" widget, the Samsung Free/Discover feed, OEM themes and icon packs, and Samsung DeX layouts.
- Widgets and folders must be set up again. Lawnchair can import a Nova backup; the others start empty.
- An app installed outside a store client does not update itself (§5).

## 5. Install and switch (each step needs approval)

1. **Install, preferred: Play Store on the device.** The user installs it there. It's signed by Play, updates automatically, and needs no "Install unknown apps" permission.
2. **Install, alternative: F-Droid client on the device** for launchers only on F-Droid. This grants F-Droid "Install unknown apps". Fine on the user's own phone, but don't do it on a child's device.
3. **Install, alternative: from the computer over ADB**, when the user doesn't want a store client on the phone (for example on a managed family device). Follow `changes.md` → Install a launcher APK. This needs no on-device sideloading permission, but the user has to update the launcher the same way later. Mention it in the follow-up check.
4. **Make it the default:** Settings → Apps → Default apps → Home app (simplest for the user to reverse), or over ADB via `changes.md` → Set the default home app.
5. **Verify:** ask the user to press Home, open the app drawer, open Recents, and use the back gesture. If anything misbehaves, roll back the home-role change first.
6. **Keep it measurable:** if speed was the reason, repeat the §1 kill count and janky-frame check after a day or two of normal use, and compare.
