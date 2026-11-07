# Audit: performance

First ask what feels slow: everything, one app, after a while, when hot, or when storage is nearly full. That decides which checks matter.

## Collect

```bash
adb -s SERIAL shell uptime                                  # load averages
adb -s SERIAL shell top -b -n 1 -m 15                       # current top processes
adb -s SERIAL shell dumpsys cpuinfo | head -30              # recent CPU load by process
adb -s SERIAL shell dumpsys thermalservice > SESSION/thermal.txt; grep -nE "Thermal Status|mTemperature|Temperature\{" SESSION/thermal.txt | head -20   # Android 10+
adb -s SERIAL shell df -h /data                             # <10% free can slow the device
```

Memory pressure: see `audits/memory.md`. Crash loops: see `audits/errors.md`.

**Jank in one app** (after the user reproduces the slowness):
```bash
adb -s SERIAL shell dumpsys gfxinfo PACKAGE > SESSION/gfxinfo.txt
grep -nE "Total frames rendered|Janky frames|50th percentile|90th percentile|99th percentile" SESSION/gfxinfo.txt
```

## Interpret

- Sustained high CPU from one optional background app is actionable. Brief spikes are not.
- Thermal status above 0 or a high skin temperature means throttling. The fix is cooling, the case, charging habits, or reducing the load, not disabling thermal controls.
- Very low free storage degrades I/O. Hand off to `audits/storage.md`.

## Options (approval required)

- Remove, disable, or restrict a confirmed unnecessary app or service.
- Animation scales of `0.5` or `0` make the phone feel faster. This changes visual behavior, not raw CPU speed (`changes.md`).
- Update or report an app with repeated crashes or high resource use.

Never force maximum refresh rate, disable thermal controls, change CPU governors, disable power management, or apply undocumented performance flags.
