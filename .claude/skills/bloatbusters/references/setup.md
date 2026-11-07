# ADB setup and connection troubleshooting

Use this when `adb` is not installed, no device is listed, or the device state is anything other than `device`. Diagnose the specific failure; do not loop on `adb devices`.

## 1. Install Android Platform Tools on the computer

Check first: `adb version`. Platform Tools 30.0.0 or newer is needed for wireless pairing (`adb pair`); prefer the latest release.

| OS | Install |
|---|---|
| macOS | `brew install --cask android-platform-tools` |
| Windows | `winget install Google.PlatformTools` |
| Debian/Ubuntu | `sudo apt install adb` (distro builds can lag; use the official zip if `adb pair` is missing) |
| Fedora | `sudo dnf install android-tools` |
| Arch | `sudo pacman -S android-tools` |
| Any | Official zip from https://developer.android.com/tools/releases/platform-tools, unzipped and added to `PATH` |

Installing software changes the user's machine. Show the command and let the user run it (they can type `! <command>` in Claude Code), or run it only after they approve. Do not download Platform Tools from mirrors or third-party sites.

After installing, open a new shell or confirm `PATH`, then re-run `adb version`.

**Multiple adb copies:** If you see `adb server version (X) doesn't match this client (Y)`, more than one adb is installed (often Android Studio's SDK copy plus a package-manager copy). Run `which -a adb` (`where adb` on Windows), have the user keep one on `PATH`, then `adb kill-server`.

## 2. Prepare the phone

1. **Enable Developer options:** Settings → About phone → tap **Build number** seven times. Samsung: Settings → About phone → Software information → Build number. Xiaomi: tap **MIUI/HyperOS version**.
2. **Enable USB debugging:** Settings → System → Developer options → **USB debugging** (location varies by OEM).
3. **Xiaomi/Redmi/POCO:** Some package and permission commands fail with `SecurityException` unless **USB debugging (Security settings)** is also enabled. That toggle requires a Mi account and SIM; enable it only if a command actually fails.
4. **Connect and unlock** the phone. When prompted with **Allow USB debugging?**, check the RSA fingerprint, then allow. Tick "Always allow from this computer" only on the user's own trusted machine.

## 3. Wireless debugging (Android 11+)

Use this when there is no cable or the USB connection is unreliable. Phone and computer must be on the same trusted network; do not use public Wi-Fi.

1. Developer options → **Wireless debugging** → on → **Pair device with pairing code**.
2. Pair (the code is single-use; the user may prefer to run it themselves with `!`):
   ```bash
   adb pair IP:PAIRING_PORT PAIRING_CODE
   ```
3. Connect using the IP and port shown on the main **Wireless debugging** screen. This port differs from the pairing port:
   ```bash
   adb connect IP:PORT
   ```
4. The serial is now `IP:PORT`; use it with `-s`. Ports change when wireless debugging restarts, so re-check `adb devices -l` if commands start failing.

On Android 10 and earlier, wireless ADB needs a one-time USB connection: `adb -s SERIAL tcpip 5555`, then `adb connect IP:5555`.

## 4. Diagnose device state

Run `adb devices -l` and match the state:

| State / symptom | Cause | Fix |
|---|---|---|
| USB debugging toggle greyed out (Samsung, One UI 6+) | **Auto Blocker** blocks USB commands | Settings → Security and privacy → Auto Blocker → off, then enable USB debugging. Remind the user to turn Auto Blocker back on after the session (and off again for `undo.sh`). Also check that "Block USB connections while locked" is off, if present |
| USB debugging toggle greyed out (supervised child account) | Family Link may block Developer options | The parent allows it in Family Link for the session (`audits/kids.md`) |
| Not listed at all | Charge-only cable, USB mode, driver, or debugging off | Try a known data cable and a different port; set USB mode to **File transfer**; confirm USB debugging is on; Windows: install the OEM USB driver (Google USB Driver for Pixel) |
| `unauthorized` | Authorization prompt not accepted | Unlock the phone and accept the prompt. If no prompt appears: Developer options → **Revoke USB debugging authorizations**, unplug, `adb kill-server`, reconnect |
| `offline` | Stale connection or old adb | Unplug and reconnect, `adb kill-server && adb start-server`, update Platform Tools |
| `no permissions` (Linux) | Missing udev rule | Install `android-sdk-platform-tools-common` (Debian/Ubuntu) or `android-udev-rules`, add the user to the `plugdev` group, re-login, reconnect |
| Several devices or emulators | Ambiguous target | Ask the user which serial; use `-s SERIAL` everywhere |
| Works, then commands hang | Phone locked or screen-off USB suspend | Keep the phone unlocked while running write commands |

Do not run `adb kill-server` repeatedly or loop on reconnect attempts. After two failed attempts, stop, report the exact state and error text, and ask the user what they see on the phone.

## 5. Security notes for the user

- USB debugging gives the connected computer broad control over the phone. Authorize only the user's own trusted computer.
- When finished, they may want to turn off USB/Wireless debugging and revoke debugging authorizations.
- Never ask for or store the phone's PIN, password, or account credentials.
