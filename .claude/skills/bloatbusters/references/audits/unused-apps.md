# Audit: unused-app cleanup

## Collect

```bash
adb -s SERIAL shell pm list packages -3 -i > SESSION/third_party.txt      # user-installed + installer
adb -s SERIAL shell pm list packages -s > SESSION/system.txt              # preinstalled
adb -s SERIAL shell pm list packages -d > SESSION/disabled.txt            # already disabled (not by us, unless in the change log)
adb -s SERIAL shell pm list packages -s -u > SESSION/system_all.txt       # system packages, including ones uninstalled for user 0
wc -l SESSION/third_party.txt SESSION/system.txt SESSION/disabled.txt SESSION/system_all.txt
```

**Usage evidence**, per candidate (read-only loop over the third-party list is fine):
```bash
adb -s SERIAL shell am get-standby-bucket PACKAGE           # 40 rare / 45 restricted / 50 never = little recent use
adb -s SERIAL shell dumpsys package PACKAGE | grep -E "firstInstallTime|lastUpdateTime|versionName"
```

Optional, heavier: `dumpsys usagestats > SESSION/usagestats.txt`, then grep for `package=PACKAGE` near `lastTimeUsed`. The format varies by version, and history may be truncated or reset.

`installer=` in the `-i` output shows the install source (`com.android.vending` = Play Store; `null` = sideloaded or preinstalled).

**Auto-pause for unused apps** (Android 11+ revokes permissions of unused apps; Android 12+ also hibernates them):
```bash
adb -s SERIAL shell cmd appops get PACKAGE AUTO_REVOKE_PERMISSIONS_IF_UNUSED   # "ignore" = the user or app opted out
```
If many rarely used apps opted out, suggest turning **Pause app activity if unused** back on for them (Settings → Apps → APP). That gets most of the benefit of removing them without removing them.

## Changes made before Bloatbusters

Another debloat tool, an earlier manual session, or the user may already have disabled or removed system packages. These often explain broken features (missing share targets, broken camera modes, failed updates).

- **Uninstalled for user 0:** packages in `system_all.txt` but not in `system.txt`. Compare with a small local script.
- **Disabled:** packages in `disabled.txt`.

Remove anything that appears in `~/.bloatbusters/RO_SERIALNO/changes.jsonl` (Bloatbusters did it). Report the rest as "changed before Bloatbusters, by an unknown tool or the user". Don't judge whether it was a mistake. If the user reports a broken feature, or a package looks protected (SKILL.md §2), offer to restore it (`changes.md`, Restore a package changed before Bloatbusters). `audits/errors.md` cross-checks crashes against this list.

## Third-party cleaners and boosters

"Cleaner", "booster", "RAM optimizer", "battery saver", "junk remover", and duplicate antivirus apps usually cost more battery and memory than they save, and they often show ads. Find candidates by package name (a guess, so confirm with the user):
```bash
grep -iE "clean|boost|junk|speed|optimi[sz]|battery|antivirus|security|ram" SESSION/third_party.txt
```
Many legitimate apps match these words. Check what each one is and whether it holds special access (`audits/privacy.md`). Recommend uninstalling confirmed cleaners through Settings. Android already manages memory and caches.

## Common optional preinstalled categories

These categories are frequent, low-risk disable candidates. They are leads to confirm with the user, not a script to run. Check every one against the protected-state snapshot.

| Category | How to spot it | Notes |
|---|---|---|
| Preinstalled Facebook services | `com.facebook.appmanager`, `com.facebook.services`, `com.facebook.system` | Background helpers for Facebook apps. Safe to disable if the user doesn't use Facebook apps, or reinstalls them from the Play Store |
| Carrier and OEM app installers ("app recommendations" during setup) | Package prefixes `com.dti.` (Digital Turbine), `com.aura.oobe.` (AppCloud/Aura); names containing `appmanager`, `appselector`, `ignite` | They install sponsored apps silently. Disable only, as some are tied to carrier setup on first boot |
| OEM ad and analytics services | `com.miui.msa.global`, `com.miui.analytics` (Xiaomi); lock-screen content services matching `glance` | Turn off recommendations in Settings first. Disable only after approval |
| Duplicate OEM apps | A second browser, app store, music player, or email client from the OEM, alongside the Google one the user actually uses | Never disable the app that holds the default role (snapshot) |
| Samsung feeds and promos | `com.samsung.android.app.spage` (Samsung Free / Bixby Home feed), `com.samsung.sree` (Samsung Global Goals) | Turn the feed page off in home-screen settings first (`audits/launcher.md` §2). Names vary by One UI version, so confirm each one |
| Trial and game hubs | Preinstalled games, "game center" stubs, trial apps | Confirm the user doesn't use them |

If a package isn't clearly in one of these categories and the user doesn't recognize it, it stays: unknown means protected.

## Classify honestly

| Evidence | Label |
|---|---|
| Last-used date available | "last used DATE" |
| Bucket 40–50, no usage record in the window | "no recorded use in the available window" |
| Preinstalled, unclear usage | "preinstalled, usage unclear" |
| No reliable data | "no reliable usage data" |

Never say "never used" unless the evidence supports it. Never recommend removal based only on missing usage records.

## Present

Table: package, likely app name (mark it as a guess when inferred from the package name), install source, usage evidence, risk. Ask the user which ones they recognize and still need. Cross-check every candidate against the protected-state snapshot and the protected-component list.

Default action for a confirmed-unneeded app:

- **User-installed, might want it back later (Android 15+):** **Archive** it. Settings → Apps → APP → Archive (or Play Store → Manage apps). Archiving removes the app but keeps its data and icon, and tapping the icon reinstalls it. The Play Store can also auto-archive rarely used apps when storage is low (Play Store → Settings → General → Automatically archive apps).
- **User-installed, definitely not needed:** uninstall normally (Settings or Play Store). This deletes the app's data, so say so.
- **Preinstalled:** `pm disable-user` (see `changes.md`).
