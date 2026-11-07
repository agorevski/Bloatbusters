# Audit: RAM / memory

## Collect

```bash
adb -s SERIAL shell cat /proc/meminfo | head -20
adb -s SERIAL shell dumpsys meminfo > SESSION/meminfo.txt
grep -n -A 30 -E "Total (PSS|RSS) by process" SESSION/meminfo.txt | head -40
grep -n -A 12 -E "Total (PSS|RSS) by OOM adjustment" SESSION/meminfo.txt
grep -nE "Total RAM|Free RAM|Used RAM|Lost RAM|ZRAM" SESSION/meminfo.txt
adb -s SERIAL logcat -d -b events -t 3000 | grep -cE "am_kill|am_low_memory"     # recent low-memory kills
adb -s SERIAL shell cat /proc/pressure/memory 2>/dev/null                         # PSI, if readable
```

Drill into one app: `adb -s SERIAL shell dumpsys meminfo PACKAGE`.

## Interpret

- Cached processes and high "used" RAM are normal. Android reclaims memory on demand. A full RAM graph is not a problem.
- Real pressure looks like frequent `am_kill`/low-memory events, apps reloading when switched back, high PSI `some`/`full` averages, or swap/ZRAM near its limit.
- Look for a single optional app with unusually large or growing memory, or a user-installed persistent service.

## Recommendations

Only for a demonstrated problem: update or report a leaking app, restrict or remove a confirmed-unneeded user app or service. Never recommend task killers, routine force-stops, or disabling core services to make the numbers look better.

If a third-party "RAM booster" or cleaner is installed, it is likely part of the problem: it kills apps that Android then restarts. Recommend removing it (`audits/unused-apps.md`). Also check for **Don't keep activities** and a **Background process limit** left on in Developer options (`audits/performance.md`), which cause constant reloading that looks like memory pressure.
