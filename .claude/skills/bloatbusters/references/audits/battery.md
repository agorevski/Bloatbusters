# Audit: battery life

`SESSION` is the session directory from SKILL.md §3. Save large dumps there and grep them; do not print them.

## Collect

```bash
adb -s SERIAL shell dumpsys battery                                   # level, status, temperature (tenths of °C), voltage
adb -s SERIAL shell dumpsys batterystats --charged > SESSION/batterystats.txt
wc -l SESSION/batterystats.txt
grep -n -A 40 "Estimated power use" SESSION/batterystats.txt          # per-UID attribution, if present
grep -n -A 30 "All partial wake locks" SESSION/batterystats.txt       # long wakelocks
grep -n -A 20 "All kernel wake locks\|Wakeup reason" SESSION/batterystats.txt | head -60
adb -s SERIAL shell dumpsys deviceidle whitelist                      # apps exempt from Doze
adb -s SERIAL shell dumpsys alarm > SESSION/alarm.txt; grep -n -A 25 "Top Alarms" SESSION/alarm.txt
```

Section names vary by Android version. If a grep finds nothing, list headers with `grep -nE "^  [A-Z][A-Za-z ]+:$" SESSION/batterystats.txt | head -40` and adapt.

**Map UIDs to packages:** `u0a123` is app UID `10123`.
```bash
adb -s SERIAL shell pm list packages -U | grep -E "uid:10123$"
```

**Per-candidate checks** (read-only; a loop over a short reviewed list is fine):
```bash
adb -s SERIAL shell am get-standby-bucket PACKAGE                      # 5 exempt, 10 active, 20 working set, 30 frequent, 40 rare, 45 restricted, 50 never
adb -s SERIAL shell cmd appops get PACKAGE RUN_ANY_IN_BACKGROUND
adb -s SERIAL shell dumpsys package PACKAGE | grep -E "ACCESS_BACKGROUND_LOCATION|ACCESS_FINE_LOCATION"
```

Also consider location mode, always-on scanning, hotspot, sync, screen brightness/timeout, and refresh rate when the symptom points there. Explain the Settings path; don't change them silently.

## Interpret

- `--charged` covers the time since the last full charge. State that window, and note that a recent drain event may be diluted.
- A high-attribution app is a lead, not proof. Correlate with wakelocks, alarms, crashes/restarts (`audits/errors.md`), and location use.
- Screen, cellular radio, and Wi-Fi often dominate. Say so instead of blaming apps.
- Do not reset batterystats to get a clean report.

## Typical recommendations (each needs approval; see `changes.md`)

- Restrict background activity for a specific app (AppOps or Settings → Battery → Restricted).
- Downgrade location access from "all the time" to "while in use" for an app that doesn't need background location.
- Disable or remove a clearly optional, user-confirmed app.
- Adjust a user-facing display or connectivity setting when the trade-off is clear.

Never promise a specific percentage of battery improvement.
