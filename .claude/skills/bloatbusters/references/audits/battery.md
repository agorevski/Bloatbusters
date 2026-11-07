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
grep -nE "Discharge|Screen off discharge|Screen on discharge|Time on battery|Screen off" SESSION/batterystats.txt | head -12   # drain totals for metrics.jsonl
grep -nE "Signal levels|Phone signal levels|Mobile radio active|Wifi scan|Bluetooth scan" SESSION/batterystats.txt | head -12   # radio cost
```

**Background work** (save, then count by package):
```bash
adb -s SERIAL shell dumpsys jobscheduler > SESSION/jobs.txt
grep -E "^ +JOB #" SESSION/jobs.txt | grep -oE "[a-z][A-Za-z0-9_]*(\.[A-Za-z0-9_]+)+/" | sort | uniq -c | sort -rn | head -15   # registered jobs per package
adb -s SERIAL shell dumpsys activity services > SESSION/services.txt
awk '/\* ServiceRecord\{/{svc=$NF} /isForeground=true/{print svc}' SESSION/services.txt | sort | uniq -c | sort -rn | head   # running foreground services
adb -s SERIAL shell dumpsys location > SESSION/location.txt
grep -nE "Active Requests|Location Request|request=" SESSION/location.txt | head -20         # who is asking for location now
```

**Battery-relevant settings** (read-only):
```bash
adb -s SERIAL shell 'for k in wifi_scan_always_enabled ble_scan_always_enabled mobile_data_always_on low_power; do echo "global $k=$(settings get global $k)"; done; echo "secure doze_always_on=$(settings get secure doze_always_on)"; for k in screen_brightness_mode screen_off_timeout peak_refresh_rate min_refresh_rate; do echo "system $k=$(settings get system $k)"; done; cmd uimode night'
```

**Battery health:**
```bash
adb -s SERIAL shell dumpsys battery | grep -iE "health|cycle|capacity|charge counter"
adb -s SERIAL shell cat /sys/class/power_supply/battery/cycle_count 2>/dev/null   # readable on some devices only
```
`health: 2` means good. If no cycle count or health percentage is printed, use Settings → Battery → Battery health (recent Pixels), or Samsung Members → Diagnostics → Battery status. Don't estimate battery wear from voltage.

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

Also consider location mode, hotspot, sync (`audits/accounts-sync.md`), and the settings above when the symptom points there. Explain the Settings path; don't change them silently.

**OEM background managers:** Samsung (Settings → Battery → Background usage limits: Sleeping and Deep sleeping apps), Xiaomi/HyperOS (Settings → Apps → APP → Autostart and Battery saver), OnePlus/Oppo/Realme (per-app "Optimize battery use" / "Allow background activity"), and Huawei (App launch) restrict apps beyond stock Android. ADB doesn't reliably show these lists. Ask the user to check them when a specific app's behavior is the question. dontkillmyapp.com documents per-OEM steps.

## Interpret

- `--charged` covers the time since the last full charge. State that window, and note that a recent drain event may be diluted.
- A high-attribution app is a lead, not proof. Correlate with wakelocks, alarms, crashes/restarts (`audits/errors.md`), and location use.
- Screen, cellular radio, and Wi-Fi often dominate. Say so instead of blaming apps.
- Do not reset batterystats to get a clean report.
- **Poor signal** (lots of time at signal level 0–1, high mobile radio active time) can drain more than any app. Recommend Wi-Fi calling or Wi-Fi where coverage is weak, not app changes.
- Running foreground services and frequent jobs are leads to correlate with attribution, not findings by themselves. Music, navigation, fitness, and VPN apps are expected to run them.
- `mobile_data_always_on=1`, scanning on while Wi-Fi/Bluetooth are off, always-on display, manual high brightness, a forced peak refresh rate (`min_refresh_rate` at the panel maximum), and light theme on an OLED screen are each small but real costs. Present them as trade-offs.
- Battery `health` other than good, or a worn battery per the OEM tool, explains drain that no software change can fix. Say so.

## The reverse problem: late notifications and missed alarms

If the complaint is that messages arrive late or alarms don't fire, the cause is usually too much restriction, not too little. Check the app's standby bucket (45 = restricted), `RUN_ANY_IN_BACKGROUND`, whether it was restricted by an earlier Bloatbusters change (`changes.jsonl`), and the OEM background manager above. The fix is to unrestrict that one app (`changes.md`, AppOps, `ignore` → `allow`) or add it to the OEM's "never sleeping" list.

## Typical recommendations (each needs approval; see `changes.md`)

- Restrict background activity for a specific app (AppOps or Settings → Battery → Restricted).
- Downgrade location access from "all the time" to "while in use" for an app that doesn't need background location.
- Disable or remove a clearly optional, user-confirmed app.
- Adjust a user-facing display or connectivity setting when the trade-off is clear. The documented keys are in the `changes.md` settings table, and dark mode is under `changes.md` Dark mode.
- Remove a user-added battery-optimization exemption for an app that doesn't need one (`changes.md`).
- Turn on the charging limit for phones kept plugged in for long periods: Pixel Settings → Battery → Charging optimization; Samsung Settings → Battery → More battery settings → Battery protection. Settings only.

Never promise a specific percentage of battery improvement.
