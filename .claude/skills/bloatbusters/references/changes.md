# Applying approved changes

Read this before making any change. Every change must be explicitly approved, reversible, recorded in the undo script **before** it is applied, verified, and logged.

## Per-device state directory

Everything Bloatbusters records about a phone lives in `~/.bloatbusters/RO_SERIALNO/` (`ro.serialno` from the baseline, not the adb serial, because wireless serials change):

| File | Purpose |
|---|---|
| `undo.sh` | Runner the user can execute any time to reverse all recorded changes, newest first |
| `undo-steps.txt` | One rollback command per change, `TIMESTAMP<TAB>COMMAND`, appended before each change |
| `changes.jsonl` | Audit trail of changes and restores |

Set it up once per session, before the first change. Refreshing `undo.sh` is safe because it holds no state:

```bash
mkdir -p -m 700 ~/.bloatbusters/RO_SERIALNO
cp SKILL_BASE_DIR/scripts/undo.sh ~/.bloatbusters/RO_SERIALNO/undo.sh
chmod 700 ~/.bloatbusters/RO_SERIALNO/undo.sh
```

`SKILL_BASE_DIR` is this skill's base directory, shown when the skill loads.

## Reversibility is mandatory

Only make a change if its rollback is one of the forms `undo.sh` accepts:

| Change | Rollback written to `undo-steps.txt` |
|---|---|
| `pm disable-user --user 0 PKG` | `pm enable --user 0 PKG` |
| `pm uninstall --user 0 PKG` (system-image packages only) | `cmd package install-existing --user 0 PKG` |
| `cmd appops set PKG OP MODE` | `cmd appops set PKG OP PRIOR_MODE` |
| `settings put NS KEY VALUE` | `settings put NS KEY PRIOR` or `settings delete NS KEY` if prior was `null` |
| `pm revoke PKG PERM` | `pm grant PKG PERM` |

If a change cannot be expressed this way (for example a prior settings value containing spaces, or removing a user-installed app), it is **not** a Bloatbusters ADB change. Guide the user through Android Settings or the Play Store instead, and say why.

## Procedure for each change

1. **Preflight:** confirm the serial is attached (`adb devices -l`), the user approved this exact item, and the target is not in the protected-state snapshot (SKILL.md §3).
2. **Record the prior state** (commands below). If the target is already in the desired state, stop. Do not change or log it.
3. **Append the undo step first**, so an interrupted session still leaves a working rollback:
   ```bash
   printf '%s\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" 'pm enable --user 0 com.example.app' >> ~/.bloatbusters/RO_SERIALNO/undo-steps.txt
   ```
   Every rollback restores a recorded prior state, so it is harmless even if the change then fails.
4. **Apply** the change with `adb -s SERIAL shell ...`.
5. **Verify** (below).
6. **Log** one JSON line, including failures:
   ```bash
   printf '%s\n' '{"ts":"2026-01-01T12:00:00Z","device":"RO_SERIALNO","fingerprint":"BUILD_FINGERPRINT","type":"disable","target":"com.example.app","prior":"enabled","command":"pm disable-user --user 0 com.example.app","result":"ok","rollback":"pm enable --user 0 com.example.app","reason":"unused for 90+ days, user confirmed"}' >> ~/.bloatbusters/RO_SERIALNO/changes.jsonl
   ```
   `type` is one of `disable`, `uninstall`, `setting`, `appops`, `permission`, `restore`. Keep `reason` free of personal data. Never edit or delete existing lines in either file.
7. **Tell the user** what changed and remind them of the rollback: `~/.bloatbusters/RO_SERIALNO/undo.sh` (or `--dry-run` to preview).

## Disable a package (preferred)

```bash
adb -s SERIAL shell pm list packages -d | grep -Fx "package:PACKAGE"   # prior: empty means enabled
adb -s SERIAL shell pm disable-user --user 0 PACKAGE
adb -s SERIAL shell pm list packages -d | grep -Fx "package:PACKAGE"   # verify: should print the package
```

Use `grep -Fx` because `pm list packages FILTER` matches substrings and can report the wrong package.

## Uninstall for user 0 (system-image packages only, when specifically approved)

```bash
adb -s SERIAL shell pm path PACKAGE    # must be under /system, /product, /vendor, /system_ext, or /odm
```

If the path is under `/data/app`, stop. Uninstalling would delete the app and its data with no ADB rollback; disable it instead, or let the user uninstall it through the Play Store. Otherwise:

```bash
adb -s SERIAL shell pm uninstall --user 0 PACKAGE
adb -s SERIAL shell pm list packages | grep -Fx "package:PACKAGE"      # verify: should print nothing
adb -s SERIAL shell pm list packages -u | grep -Fx "package:PACKAGE"   # should still print: kept in the system image
```

Warn that restoring with `install-existing` brings the app back but not its data. Prefer disabling when that meets the goal. Never use `-k`.

## Restrict background activity (AppOps)

Comparable to the "Restricted" battery option. Prefer Settings → Apps → APP → Battery when that UI exists.

```bash
adb -s SERIAL shell cmd appops get PACKAGE RUN_ANY_IN_BACKGROUND        # prior mode
adb -s SERIAL shell cmd appops set PACKAGE RUN_ANY_IN_BACKGROUND ignore
adb -s SERIAL shell cmd appops get PACKAGE RUN_ANY_IN_BACKGROUND        # verify
```

Restricted apps may deliver notifications late and miss background sync. Do not apply this to messaging, alarm, health, security, or authentication apps unless the user insists.

## Change a setting

Only documented keys. Read, change, read back:

```bash
adb -s SERIAL shell settings get NAMESPACE KEY     # prior; "null" means unset
adb -s SERIAL shell settings put NAMESPACE KEY VALUE
adb -s SERIAL shell settings get NAMESPACE KEY     # verify
```

| Purpose | Namespace / key | Values |
|---|---|---|
| Animation scales | `global window_animation_scale`, `global transition_animation_scale`, `global animator_duration_scale` | `1.0` default, `0.5` faster-feeling, `0` off |
| Screen timeout | `system screen_off_timeout` | milliseconds |

For anything else, give the user the Settings-app path.

## Runtime permissions

Prefer Settings → Apps → APP → Permissions. Use ADB only if the user prefers it, one package and one permission at a time:

```bash
adb -s SERIAL shell dumpsys package PACKAGE | grep -F "PERMISSION:"    # prior: granted=true/false
adb -s SERIAL shell pm revoke PACKAGE PERMISSION
adb -s SERIAL shell dumpsys package PACKAGE | grep -F "PERMISSION:"    # verify
```

Revoking may kill the app process. `android.permission.POST_NOTIFICATIONS` is a runtime permission only on Android 13+ (SDK 33). Notification channels have no reliable ADB command; use Settings → Notifications → App notifications → APP.

## Verify after every change

1. Check the command's exit status and output (`Success`, `new state: disabled-user`, and so on).
2. Re-read the state as above.
3. Look for immediate breakage: `adb -s SERIAL logcat -d -b crash -t 100`.

For battery, memory, and performance, a before/after snapshot is not a benchmark. Explain what can be measured now and what needs days of similar usage to compare.
