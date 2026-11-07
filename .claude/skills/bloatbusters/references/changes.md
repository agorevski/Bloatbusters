# Applying approved changes

Read this before making any change. Every change must be explicitly approved, reversible, recorded in the undo script **before** it is applied, verified, and logged. The only exceptions are the maintenance commands listed in [Approval-only maintenance commands](#approval-only-maintenance-commands-not-undoable).

If something breaks after a change (launcher or System UI gone, boot loop, recovery screen), stop and read `recovery.md`.

## Per-device state directory

Everything Bloatbusters records about a phone lives in `~/.bloatbusters/RO_SERIALNO/` (`ro.serialno` from the baseline, not the adb serial, because wireless serials change). If SKILL.md §3 found `ro.serialno` unusable, make no ADB changes.

| File | Purpose |
|---|---|
| `undo.sh` | Runner the user can execute any time to reverse all recorded changes, newest first |
| `undo-steps.txt` | One rollback command per change, `TIMESTAMP<TAB>COMMAND`, appended before each change |
| `changes.jsonl` | Audit trail of changes, maintenance runs, and restores |
| `metrics.jsonl` | One line of redacted, numbers-only measurements per session (`audits/follow-up.md`) |

Set it up once per session, before the first change. Refreshing `undo.sh` is safe because it holds no state:

```bash
mkdir -p -m 700 ~/.bloatbusters/RO_SERIALNO
cp SKILL_BASE_DIR/scripts/undo.sh ~/.bloatbusters/RO_SERIALNO/undo.sh
chmod 700 ~/.bloatbusters/RO_SERIALNO/undo.sh
```

`SKILL_BASE_DIR` is this skill's base directory, shown when the skill loads.

## Scope: user 0 only

Every change targets the owner profile (`--user 0`). Work profiles, Samsung Secure Folder, Xiaomi Dual Apps, and secondary users (SKILL.md §3) are inspected read-only and never changed. A work profile belongs to the user's employer, and its admin will usually reverse or block changes there. If the current foreground user is not 0, make no changes.

## Reversibility is mandatory

Only make a change if its rollback is one of the forms `undo.sh` accepts:

| Change | Rollback written to `undo-steps.txt` |
|---|---|
| `pm disable-user --user 0 PKG` | `pm enable --user 0 PKG` |
| `pm enable --user 0 PKG` (re-enabling something disabled before Bloatbusters) | `pm disable-user --user 0 PKG` |
| `pm uninstall --user 0 PKG` (system-image packages only) | `cmd package install-existing --user 0 PKG` |
| `cmd package install-existing --user 0 PKG` (restoring a system package removed before Bloatbusters) | `pm uninstall --user 0 PKG` |
| `cmd appops set PKG OP MODE` | `cmd appops set PKG OP PRIOR_MODE` |
| `settings put NS KEY VALUE` | `settings put NS KEY PRIOR` or `settings delete NS KEY` if prior was `null` |
| `pm revoke PKG PERM` | `pm grant PKG PERM` |
| `dumpsys deviceidle whitelist -PKG` (remove a user-added battery-optimization exemption) | `dumpsys deviceidle whitelist +PKG` |
| `cmd netpolicy add restrict-background-blacklist UID` (block background mobile data) | `cmd netpolicy remove restrict-background-blacklist UID` |
| `cmd uimode night yes\|no\|auto` | `cmd uimode night PRIOR` |
| `cmd role add-role-holder --user 0 android.app.role.HOME PKG` (default home app) | `cmd role add-role-holder --user 0 android.app.role.HOME PRIOR_PKG` |
| `adb install` of a launcher APK (`audits/launcher.md`) | `pm disable-user --user 0 PKG` (the user uninstalls it in Settings to remove it completely) |

`undo.sh` skips a `pm uninstall` rollback unless the package is part of the system image, so a bad log line can never delete a user-installed app.

If a change cannot be expressed this way (for example a prior settings value containing spaces, a custom dark-mode schedule, or removing a user-installed app), it is **not** a Bloatbusters ADB change. Guide the user through Android Settings or the Play Store instead, and say why.

## Procedure for each change

1. **Preflight:** confirm the serial is attached (`adb devices -l`), the user approved this exact item, and the target is not in the protected-state snapshot (SKILL.md §3).
2. **Record the prior state** (commands below). If the target is already in the desired state, stop. Do not change or log it.
3. **Append the undo step first**, so an interrupted session still leaves a working rollback:
   ```bash
   printf '%s\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" 'pm enable --user 0 com.example.app' >> ~/.bloatbusters/RO_SERIALNO/undo-steps.txt
   ```
   Every rollback restores a recorded prior state, so it is harmless even if the change then fails.
4. **Apply** the change with `adb -s SERIAL shell ...`. Keep the phone unlocked and connected.
5. **Verify** (below). Do not start the next change until this one is verified.
6. **Log** one JSON line, including failures:
   ```bash
   printf '%s\n' '{"ts":"2026-01-01T12:00:00Z","device":"RO_SERIALNO","fingerprint":"BUILD_FINGERPRINT","type":"disable","target":"com.example.app","prior":"enabled","command":"pm disable-user --user 0 com.example.app","result":"ok","rollback":"pm enable --user 0 com.example.app","reason":"unused for 90+ days, user confirmed"}' >> ~/.bloatbusters/RO_SERIALNO/changes.jsonl
   ```
   `type` is one of `disable`, `enable`, `uninstall`, `install-existing`, `install`, `role`, `setting`, `appops`, `permission`, `deviceidle`, `netpolicy`, `uimode`, `maintenance`, `restore`. Keep `reason` free of personal data. Never edit or delete existing lines in either file.
7. **Tell the user** what changed and remind them of the rollback: `~/.bloatbusters/RO_SERIALNO/undo.sh` (or `--dry-run` to preview).

## Disable a package (preferred)

```bash
adb -s SERIAL shell pm list packages -d | grep -Fx "package:PACKAGE"   # prior: empty means enabled
adb -s SERIAL shell pm disable-user --user 0 PACKAGE
adb -s SERIAL shell pm list packages -d | grep -Fx "package:PACKAGE"   # verify: should print the package
```

Use `grep -Fx` because `pm list packages FILTER` matches substrings and can report the wrong package.

## Uninstall for user 0 (system-image packages only, when specifically approved)

Classify the package by the system list, not by its path. An **updated system app** has its update under `/data/app`, but its factory copy is still in the system image.

```bash
adb -s SERIAL shell pm list packages -s | grep -Fx "package:PACKAGE"   # must print: system-image package
adb -s SERIAL shell dumpsys package PACKAGE | grep -E "codePath=|UPDATED_SYSTEM_APP" | head -4   # informational
```

If the package is not in the `-s` list, it is user-installed. Stop: uninstalling would delete the app and its data with no ADB rollback. Disable it instead, or let the user uninstall it through Settings or the Play Store. Otherwise:

```bash
adb -s SERIAL shell pm uninstall --user 0 PACKAGE
adb -s SERIAL shell pm list packages | grep -Fx "package:PACKAGE"      # verify: should print nothing
adb -s SERIAL shell pm list packages -u | grep -Fx "package:PACKAGE"   # should still print: kept in the system image
```

Warn that restoring with `install-existing` brings the app back but not its data, and that an updated system app may come back as its factory version until the store updates it. Prefer disabling when that meets the goal. Never use `-k`.

## Restore a package changed before Bloatbusters

For packages that `audits/unused-apps.md` found disabled or uninstalled by another tool or by the user, and that the user now wants back:

```bash
adb -s SERIAL shell pm enable --user 0 PACKAGE                          # was disabled; rollback: pm disable-user --user 0 PACKAGE
adb -s SERIAL shell cmd package install-existing --user 0 PACKAGE       # was uninstalled for user 0; rollback: pm uninstall --user 0 PACKAGE
```

Confirm first that the package is in `pm list packages -s -u` (system image). Verify with `pm list packages -d` / `pm list packages`.

## Restrict or unrestrict background activity (AppOps)

Comparable to the "Restricted" battery option. Prefer Settings → Apps → APP → Battery when that UI exists.

```bash
adb -s SERIAL shell cmd appops get PACKAGE RUN_ANY_IN_BACKGROUND        # prior mode
adb -s SERIAL shell cmd appops set PACKAGE RUN_ANY_IN_BACKGROUND ignore
adb -s SERIAL shell cmd appops get PACKAGE RUN_ANY_IN_BACKGROUND        # verify
```

Reading the prior mode:

- `RUN_ANY_IN_BACKGROUND: allow; time=...` → prior is `allow` (likewise `ignore`, `deny`, `foreground`).
- `No operations.` → the op was never set; prior is `default`.
- If a `Uid mode:` line appears, it is the UID-level mode. `cmd appops set PACKAGE ...` changes the package-level mode, so record the line **without** `Uid mode:`, or `default` if there is none.

Restricted apps may deliver notifications late and miss background sync. Do not apply this to messaging, alarm, health, security, or authentication apps unless the user insists. To fix late notifications, the reverse change (`ignore` → `allow`) follows the same procedure.

## Remove a battery-optimization exemption

Only exemptions the user (or an app prompt) added can be removed. System exemptions cannot.

```bash
adb -s SERIAL shell dumpsys deviceidle whitelist | grep -F "user,PACKAGE,"   # prior: must print a "user," line
adb -s SERIAL shell dumpsys deviceidle whitelist -PACKAGE
adb -s SERIAL shell dumpsys deviceidle whitelist | grep -F "user,PACKAGE,"   # verify: should print nothing
```

Settings path: Settings → Apps → Special app access → Battery optimization. Keep exemptions for messaging, alarm, health, VPN, companion (watch, hearing aid, car) and accessibility apps unless the user insists.

## Block background mobile data for one app

Prefer Settings → Apps → APP → Mobile data → Background data. Over ADB, the subcommand name varies by version, so check it first:

```bash
adb -s SERIAL shell cmd netpolicy help | grep -i "restrict-background"        # use the exact name listed (blacklist or denylist)
adb -s SERIAL shell pm list packages -U | grep -E "^package:PACKAGE uid:"      # UID
adb -s SERIAL shell pm list packages -U | grep -cE " uid:UID$"                  # must be 1: a shared UID restricts several apps
adb -s SERIAL shell cmd netpolicy list restrict-background-blacklist            # prior: UID must not already be listed
adb -s SERIAL shell cmd netpolicy add restrict-background-blacklist UID
adb -s SERIAL shell cmd netpolicy list restrict-background-blacklist            # verify
```

If the phone lists `denylist` instead of `blacklist`, use `denylist` in every command, including the rollback (`cmd netpolicy remove restrict-background-denylist UID`). Do not restrict shared UIDs (`1000`, `1013`, and so on) or messaging, sync, navigation, or security apps.

## Dark mode

Saves battery on OLED screens. Android 10+ (SDK 29).

```bash
adb -s SERIAL shell cmd uimode night        # prior: "Night mode: yes|no|auto|custom"
adb -s SERIAL shell cmd uimode night yes
adb -s SERIAL shell cmd uimode night        # verify
```

If the prior value is `custom` (a schedule), or anything else, use Settings → Display → Dark theme instead.

## Set the default home app (launcher)

Prefer Settings → Apps → Default apps → Home app. Over ADB (Android 10+, SDK 29), after the user picked a launcher in `audits/launcher.md`:

```bash
adb -s SERIAL shell cmd role get-role-holders --user 0 android.app.role.HOME    # prior: exactly one package
adb -s SERIAL shell cmd package query-activities --brief -a android.intent.action.MAIN -c android.intent.category.HOME | grep -F "PACKAGE/"   # must print: it is a launcher
adb -s SERIAL shell cmd role add-role-holder --user 0 android.app.role.HOME PACKAGE
adb -s SERIAL shell cmd role get-role-holders --user 0 android.app.role.HOME    # verify: PACKAGE
```

Rollback: `cmd role add-role-holder --user 0 android.app.role.HOME PRIOR_PACKAGE`. The home role has one holder, so adding the prior package replaces the new one. If the prior output is empty or lists more than one package, use the Settings path instead. Some OEM builds refuse third-party home apps over ADB. If the command errors, use Settings.

After switching, ask the user to press Home and open Recents (`audits/launcher.md` §5). Never disable the previous (stock) launcher.

## Install a launcher APK (from the computer)

Only for a launcher the user chose in `audits/launcher.md`, and only when the Play Store version isn't an option. This is the only install Bloatbusters does over ADB. It needs no "Install unknown apps" permission on the phone.

1. **Get the APK from the project's own source:** the F-Droid package page (`https://f-droid.org/packages/PACKAGE/`) or the project's GitHub releases. Never use an APK mirror site. Save it in a new, empty directory (it is untrusted data). If the project publishes a SHA-256 checksum, compare it with `shasum -a 256 FILE.apk`. If Android build-tools are installed, `apksigner verify --print-certs FILE.apk` shows the signing certificate. Compare it with the one the project publishes, if any.
2. **Preflight:** the package ID comes from the source page (it's in the F-Droid URL). It must not already be installed:
   ```bash
   adb -s SERIAL shell pm list packages -u --user 0 | grep -Fx "package:PACKAGE"   # must print nothing
   adb -s SERIAL shell pm list packages -3 --user 0 > SESSION/third_party_before.txt
   ```
3. **Undo step first:** `pm disable-user --user 0 PACKAGE`.
4. **Install:**
   ```bash
   adb -s SERIAL install --user 0 "/path/to/FILE.apk"
   ```
   Play Protect may scan it and ask the user to confirm on screen. Xiaomi needs Developer options → **Install via USB**. Samsung Auto Blocker blocks installs over USB. The user must turn it off for the session and back on afterward.
5. **Verify** that exactly the expected package appeared:
   ```bash
   adb -s SERIAL shell pm list packages -3 --user 0 > SESSION/third_party_after.txt
   diff SESSION/third_party_before.txt SESSION/third_party_after.txt                 # must show only: > package:PACKAGE
   adb -s SERIAL shell dumpsys package PACKAGE | grep -E "versionName|targetSdk" | head -2
   ```
   If a different package appeared, disable it right away (its undo step is already recorded for the expected name, so record one for the actual name first) and stop.
6. **Log** with `"type":"install"`, the version, and the source URL in `reason`.

Rollback disables the launcher rather than uninstalling it, because Bloatbusters never uninstalls user-installed apps over ADB. Tell the user that to remove it completely, they uninstall it in Settings → Apps, and that an ADB-installed app doesn't update itself. They can reinstall a newer APK the same way, or switch to the store version.

## Change a setting

Only the documented keys below. Read, change, read back:

```bash
adb -s SERIAL shell settings get NAMESPACE KEY     # prior; "null" means unset
adb -s SERIAL shell settings put NAMESPACE KEY VALUE
adb -s SERIAL shell settings get NAMESPACE KEY     # verify
```

| Purpose | Namespace / key | Values | Notes |
|---|---|---|---|
| Animation scales | `global window_animation_scale`, `global transition_animation_scale`, `global animator_duration_scale` | `1.0` default, `0.5` faster-feeling, `0` off | |
| Screen timeout | `system screen_off_timeout` | milliseconds | |
| Adaptive brightness | `system screen_brightness_mode` | `1` automatic, `0` manual | |
| Wi-Fi scanning when Wi-Fi is off | `global wifi_scan_always_enabled` | `1` on, `0` off | Off slightly reduces location accuracy |
| Bluetooth scanning when Bluetooth is off | `global ble_scan_always_enabled` | `1` on, `0` off | Off can slow Find My Device and Fast Pair |
| Mobile data always active | `global mobile_data_always_on` | `1` on (default on many builds), `0` off | Developer option. Off saves battery but slows Wi-Fi-to-mobile handoff |
| Always-on display | `secure doze_always_on` | `1` on, `0` off | Many OEMs (for example Samsung) use their own key; if `get` returns `null` while AOD is on, use Settings |
| Don't keep activities | `global always_finish_activities` | `0` off (default), `1` on | Developer option. Revert `1` to `0` (`audits/performance.md`) |
| Private DNS mode | `global private_dns_mode` | `off`, `opportunistic` (Automatic, the usual default), `hostname` | Set the specifier first, then the mode (`audits/privacy.md`) |
| Private DNS hostname | `global private_dns_specifier` | a DNS-over-TLS hostname | |

Rules:

- Never change a key that isn't in this table. For anything else, give the user the Settings-app path.
- If the prior value contains spaces or characters other than letters, digits, and `_.:,/+-`, it cannot be rolled back by `undo.sh`. Use the Settings path instead.
- Battery saver (`global low_power`) and refresh rate (`system peak_refresh_rate`, `system min_refresh_rate`) are read-only for Bloatbusters. Their behavior varies by OEM; use Settings.

## Runtime permissions

Prefer Settings → Apps → APP → Permissions. Use ADB only if the user prefers it, one package and one permission at a time:

```bash
adb -s SERIAL shell dumpsys package PACKAGE | grep -F "PERMISSION:"    # prior: granted=true/false
adb -s SERIAL shell pm revoke PACKAGE PERMISSION
adb -s SERIAL shell dumpsys package PACKAGE | grep -F "PERMISSION:"    # verify
```

Revoking may kill the app process. `android.permission.POST_NOTIFICATIONS` is a runtime permission only on Android 13+ (SDK 33). Notification channels have no reliable ADB command; use Settings → Notifications → App notifications → APP.

## Approval-only maintenance commands (not undoable)

These are the **only** ADB commands Bloatbusters may run that `undo.sh` cannot reverse. Each one runs a job Android already does on its own, and none of them changes a setting, a package state, or user data. Nothing outside this list may bypass the reversibility rule.

| Command | What it does | What can't be undone | Use only when |
|---|---|---|---|
| `pm trim-caches 999G` | Asks Android to delete app cache files across all apps, as it does itself when storage runs low | Caches are gone. Apps rebuild them, so they may be slower once, and apps that keep offline content in their cache (some music, map, or video apps) re-download it | Storage is critically low and the user has already reviewed the larger items in `audits/storage.md` |
| `sm fstrim` | Runs storage TRIM now instead of during the next idle maintenance | Nothing user-visible. May fail with a permission error on some builds; if so, stop | Storage feels slow and the phone has been off the charger for days |
| `cmd package bg-dexopt-job` | Runs the app optimization job now instead of during idle charging | Takes several minutes, uses battery, warms the phone | The phone feels slow within a few days of an OS or major app update |
| `reboot` (as `adb -s SERIAL reboot`, nothing appended) | Restarts the phone | Unsaved work in open apps is lost. Wireless debugging gets a new port and the user must unlock the phone again | Long uptime plus sluggishness, or after a set of changes when the user wants a clean start |

Rules:

1. Propose each one as its own numbered item and label it **not undoable**, with the "what can't be undone" text. Get explicit approval for that item.
2. Do not run them routinely or "just in case".
3. Never write them to `undo-steps.txt`. Log them in `changes.jsonl` with `"type":"maintenance"` and `"rollback":"none (not undoable)"`.
4. Never pass other arguments to `reboot`. `reboot bootloader`, `reboot recovery`, `reboot fastboot`, and `reboot sideload` are forbidden.

## Verify after every change

1. Check the command's exit status and output (`Success`, `new state: disabled-user`, and so on).
2. Re-read the state as above.
3. Look for immediate breakage: `adb -s SERIAL logcat -d -b crash -t 100`. Ask the user to press Home and open the app drawer and keyboard if a package was disabled or uninstalled.
4. If anything is broken, roll that change back right away (its line in `undo-steps.txt`) and see `recovery.md`.

For battery, memory, and performance, a before/after snapshot is not a benchmark. Explain what can be measured now and what needs days of similar usage to compare (`audits/follow-up.md`).
