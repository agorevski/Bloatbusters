# Audit: background errors and reliability

Start narrow; widen only if needed. Logs contain personal data, so save them to files and present redacted, minimal excerpts.

## Collect

```bash
adb -s SERIAL logcat -d -b crash > SESSION/crash.txt                                    # dedicated crash buffer
grep -oE "Process: [A-Za-z0-9._:]+" SESSION/crash.txt | sort | uniq -c | sort -rn | head
adb -s SERIAL logcat -d -b events -t 5000 > SESSION/events.txt
grep -E "am_anr|am_crash|am_proc_died" SESSION/events.txt | grep -oE "[a-z][A-Za-z0-9_]*(\.[A-Za-z0-9_]+)+" | sort | uniq -c | sort -rn | head
adb -s SERIAL shell dumpsys dropbox > SESSION/dropbox_index.txt                        # entry list only
grep -oE "(data|system)_app_(crash|anr|native_crash)|SYSTEM_TOMBSTONE|system_server_[a-z_]+" SESSION/dropbox_index.txt | sort | uniq -c
```

Drill down only for specific offenders:
```bash
adb -s SERIAL shell dumpsys activity exit-info PACKAGE | head -60                       # Android 11+: exit reasons
adb -s SERIAL shell dumpsys dropbox --print data_app_crash > SESSION/dropbox_crash.txt   # one tag at a time
adb -s SERIAL logcat -d -t 2000 > SESSION/logcat.txt                                    # main log, last resort
```

Prefer the crash and events buffers over the main log. Avoid `dumpsys dropbox --print` with no tag; it can be enormous.

## Interpret

- Look for recurring fatal exceptions, ANRs, repeated process deaths, crash loops, and failing services. Correlate package names and timestamps.
- A single warning or a one-off crash is usually not a fault.
- **Missing components:** if a crash or ANR names a class or package that isn't installed, or the log shows `ActivityNotFoundException` / `NameNotFoundException` / `Unable to find provider` for a system package, check it against the packages disabled or uninstalled before Bloatbusters (`audits/unused-apps.md`) and Bloatbusters' own `changes.jsonl`. A removed dependency is a common cause of crash loops after debloating.
- **Our own changes:** if a crash started after a Bloatbusters change (compare timestamps with `changes.jsonl`), roll that change back first (`undo.md`).
- Redact tokens, emails, phone numbers, account names, message content, and device identifiers before quoting.

## Recommend

Update the app, check for a vendor fix, change a supported setting, or clear one app's cache through Settings when there's a specific reason. Do not "fix" errors by disabling the app that logs them without understanding the impact. Never upload logs externally unless the user explicitly asks.
