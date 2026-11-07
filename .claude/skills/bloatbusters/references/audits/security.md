# Audit: security and update check-up

Read-only. Bloatbusters never changes security, encryption, lock-screen, or Play Protect settings over ADB. This audit tells the user where they stand and which Settings screens to visit.

## Collect

```bash
adb -s SERIAL shell 'for p in ro.build.version.security_patch ro.build.date ro.build.version.release ro.build.version.sdk ro.boot.verifiedbootstate ro.boot.flash.locked ro.boot.vbmeta.device_state ro.crypto.state ro.crypto.type ro.build.tags; do echo "$p=$(getprop $p)"; done'
adb -s SERIAL shell 'for k in development_settings_enabled adb_enabled adb_wifi_enabled; do echo "$k=$(settings get global $k)"; done'
adb -s SERIAL shell pm list packages -3 -i > SESSION/third_party.txt
adb -s SERIAL shell cmd appops query-op REQUEST_INSTALL_PACKAGES allow
```

**Old target SDK**, per user-installed app (read-only loop over `third_party.txt` is fine):

```bash
adb -s SERIAL shell dumpsys package PACKAGE | grep -m1 -oE "targetSdk=[0-9]+"
```

## Interpret

| Check | Healthy | Finding |
|---|---|---|
| `ro.build.version.security_patch` | Within about 3 months of today | Older: check Settings → System → Software update. If none is offered and the patch is more than a year old, the phone may be out of OEM support. Say so plainly |
| Google Play system update | Recent date | Ask the user to check Settings → Security & privacy → System & updates → Google Play system update (path varies). ADB cannot show this date reliably |
| `ro.boot.verifiedbootstate` | `green` | `orange` means the bootloader is unlocked; `yellow`/`red` mean the system image failed or bypassed verification. If the user didn't do this themselves (used or refurbished phone), it is a high-priority finding |
| `ro.boot.flash.locked` / `vbmeta.device_state` | `1` / `locked` | `0` / `unlocked`: same as above |
| `ro.crypto.state` | `encrypted` | Anything else on Android 10+ is unusual. Report it, don't try to fix it |
| `ro.build.tags` | `release-keys` | `test-keys` or `dev-keys` means a custom or engineering build |
| Developer options / ADB | Off when not in use | On now because of this session. Remind the user at wrap-up (SKILL.md §4) |
| Install unknown apps | Only apps the user deliberately uses to install APKs | Browsers, messaging, or file managers with this access are a common malware path |
| Sideloaded apps | Few, and recognized | `installer=null` for a non-preinstalled app, or an installer that is a browser or file manager |
| `targetSdk` | Recent (28+) | Apps targeting old SDKs skip newer privacy and background limits. They're often abandoned. Recommend updating or replacing them |

Also ask (don't read over ADB):

- Is a screen lock set (PIN, pattern, password, or biometrics)? Settings → Security & privacy → Device unlock.
- Is Find My Device on? Settings → Google → Find My Device (Samsung: also SmartThings Find).
- Is Play Protect on, and when did it last scan? Play Store → profile → Play Protect.
- Are app updates pending? Play Store → profile → Manage apps & device. Galaxy Store and other OEM stores have their own update pages.

## Recommend

- Install pending system, Play system, and app updates.
- Remove "Install unknown apps" access from apps that don't need it (Settings → Apps → Special app access → Install unknown apps). With approval, this can also be done over ADB as an AppOps change (`REQUEST_INSTALL_PACKAGES` → `default`/`ignore`) following `changes.md`.
- Review sideloaded or old-SDK apps with the user; uninstall unrecognized ones through Settings.
- For an unexpected unlocked bootloader or test-keys build: explain the risk (no verified boot, possible tampering) and recommend the OEM's official firmware or support. Never relock or flash anything; it can wipe or brick the phone.
- If the phone is out of support, say so, and say what that means: no more security fixes. Do not pressure the user to buy a new phone.
