# Audit: connectivity and Android Auto

## Establish the symptom first

Ask: what fails (connect, drop, slow, audio, no projection), since when, how often, and whether it affects one network/vehicle/accessory or several. Get an approximate time of a recent failure so logs can be scoped.

## Collect

These dumps contain SSIDs, MAC addresses, device names, and sometimes location-related cell info. Save them to files, grep for state, and redact before quoting.

```bash
adb -s SERIAL shell dumpsys wifi > SESSION/wifi.txt
grep -nE "Wi-Fi is|mWifiInfo|RSSI|Link speed|Frequency" SESSION/wifi.txt | head -20
adb -s SERIAL shell dumpsys bluetooth_manager > SESSION/bt.txt
grep -nE "enabled:|state:|ConnectionState|A2dp|Hfp|Bonded devices" SESSION/bt.txt | head -30
adb -s SERIAL shell dumpsys connectivity > SESSION/connectivity.txt
grep -nE "Active default network|NetworkAgentInfo|VALIDATED|PARTIAL_CONNECTIVITY|CAPTIVE_PORTAL" SESSION/connectivity.txt | head -20
```

Android Auto (built into Android 10+ but still updated as a package; layout varies by OEM/version):
```bash
adb -s SERIAL shell dumpsys package com.google.android.projection.gearhead | grep -E "versionName|enabled=|lastUpdateTime"
adb -s SERIAL shell dumpsys package com.google.android.gms | grep -m1 versionName     # Play services version matters for AA
```

Logs around the failure window only (`-t` takes `'MM-DD hh:mm:ss.mmm'`):
```bash
adb -s SERIAL logcat -d -t '11-06 08:25:00.000' > SESSION/window.txt
grep -iE "gearhead|projection|carservice|bluetooth|usb|wifi" SESSION/window.txt | head -80
```

## Recommend

Common supported fixes: update Android Auto and Play services, check the USB cable and data mode, check per-car settings in Android Auto, forget and re-pair one specific accessory, or disable battery restriction for Android Auto/the car app.

Do not reset Bluetooth, Wi-Fi, network settings, or pairings without explicit approval. Resets remove saved networks and accessories. Always name exactly what would be lost.
