# Audit: unused-app cleanup

## Collect

```bash
adb -s SERIAL shell pm list packages -3 -i > SESSION/third_party.txt      # user-installed + installer
adb -s SERIAL shell pm list packages -s > SESSION/system.txt              # preinstalled
adb -s SERIAL shell pm list packages -d > SESSION/disabled.txt            # already disabled (not by us, unless in the change log)
wc -l SESSION/third_party.txt SESSION/system.txt SESSION/disabled.txt
```

**Usage evidence**, per candidate (read-only loop over the third-party list is fine):
```bash
adb -s SERIAL shell am get-standby-bucket PACKAGE           # 40 rare / 45 restricted / 50 never = little recent use
adb -s SERIAL shell dumpsys package PACKAGE | grep -E "firstInstallTime|lastUpdateTime|versionName"
```

Optional, heavier: `dumpsys usagestats > SESSION/usagestats.txt`, then grep for `package=PACKAGE` near `lastTimeUsed`. The format varies by version, and history may be truncated or reset.

`installer=` in the `-i` output shows the install source (`com.android.vending` = Play Store; `null` = sideloaded or preinstalled).

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

Default action for a confirmed-unneeded app: user-installed apps can be uninstalled normally (Settings or Play Store). Preinstalled apps get `pm disable-user` (see `changes.md`).
