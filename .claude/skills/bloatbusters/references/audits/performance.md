# Audit: performance

First ask what feels slow: everything, one app, after a while, when hot, or when storage is nearly full. That decides which checks matter.

## Collect

```bash
adb -s SERIAL shell uptime                                  # load averages
adb -s SERIAL shell top -b -n 1 -m 15                       # current top processes
adb -s SERIAL shell dumpsys cpuinfo | head -30              # recent CPU load by process
adb -s SERIAL shell dumpsys thermalservice > SESSION/thermal.txt; grep -nE "Thermal Status|mTemperature|Temperature\{" SESSION/thermal.txt | head -20   # Android 10+
adb -s SERIAL shell df -h /data                             # <10% free can slow the device
adb -s SERIAL shell 'echo "always_finish_activities=$(settings get global always_finish_activities)"; for k in window_animation_scale transition_animation_scale animator_duration_scale low_power; do echo "$k=$(settings get global $k)"; done; for k in peak_refresh_rate min_refresh_rate; do echo "$k=$(settings get system $k)"; done; getprop ro.build.date'
```

**Folklore tweaks left behind:** look for settings that a "speed up your phone" guide may have changed and that usually make things worse:

| Setting | Healthy | Problem |
|---|---|---|
| `always_finish_activities` (Developer options → Don't keep activities) | `0` or `null` | `1` closes every app as soon as you leave it, so everything reloads |
| Developer options → Background process limit | Standard limit | Any limit makes apps restart constantly. Not stored as a setting, and it resets on reboot. Ask the user to check the screen |
| Animation scales | `1.0`, `0.5`, or `null` | Odd values (for example `10`) make the phone feel slow |
| `min_refresh_rate` (Developer options → Force peak refresh rate) | `null` or `0` | Set to the panel maximum costs battery for no gain in most apps. Turn it off in Developer options |
| `low_power` (Battery saver) | `0` most of the time | `1` all the time throttles CPU and background work. Fine if it's what the user wants |

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
- **Long uptime** (more than about 2 weeks) plus general sluggishness: a restart often helps and costs nothing. Suggest that the user restart the phone, or offer `reboot` from the approval-only maintenance list (`changes.md`).
- **Recent OS or major app update** (`ro.build.date` or the app's `lastUpdateTime` within the last few days): Android re-optimizes apps during idle charging, so the phone may feel slow for a day or two. Leaving it on the charger overnight usually fixes it. If the user doesn't want to wait, offer `cmd package bg-dexopt-job` (approval-only, `changes.md`).
- **Storage slow even with free space**, phone rarely idle on a charger: offer `sm fstrim` (approval-only, `changes.md`).

## Options (approval required)

- Remove, disable, or restrict a confirmed unnecessary app or service.
- Animation scales of `0.5` or `0` make the phone feel faster. This changes visual behavior, not raw CPU speed (`changes.md`).
- Revert folklore tweaks: `always_finish_activities` `1` → `0` (`changes.md`). Background process limit and forced peak refresh rate are set back through Developer options.
- Remove third-party cleaner or booster apps (`audits/unused-apps.md`).
- A live wallpaper or heavy launcher widgets on low-RAM phones: suggest a static wallpaper (the live wallpaper is in the protected snapshot, so change it in Settings, not by disabling it).
- Update or report an app with repeated crashes or high resource use.

Never force maximum refresh rate, disable thermal controls, change CPU governors, disable power management, or apply undocumented performance flags.
