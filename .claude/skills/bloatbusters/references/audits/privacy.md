# Audit: privacy and permissions

Focus on access that doesn't fit an app's purpose. Special access is usually more significant than ordinary runtime permissions.

## Special access (highest value)

```bash
adb -s SERIAL shell 'settings get secure enabled_accessibility_services; settings get secure enabled_notification_listeners'
adb -s SERIAL shell dumpsys device_policy | grep -iE "owner|admin"
adb -s SERIAL shell cmd appops query-op SYSTEM_ALERT_WINDOW allow          # draw over other apps
adb -s SERIAL shell cmd appops query-op GET_USAGE_STATS allow              # usage access
adb -s SERIAL shell cmd appops query-op REQUEST_INSTALL_PACKAGES allow     # install unknown apps
adb -s SERIAL shell dumpsys connectivity | grep -iE "vpn|always-on" | head
```

`query-op` support varies by version. If it errors, fall back to `cmd appops get PACKAGE` per candidate.

Accessibility services, notification listeners, and device admins can read screen content or notifications. An unexpected one is a high-priority finding. Before calling it unexpected, check whether it belongs to a password manager, VPN, MDM, or other tool the user relies on.

## Runtime permissions, per app

```bash
adb -s SERIAL shell pm list packages -3 > SESSION/third_party.txt
adb -s SERIAL shell dumpsys package PACKAGE | grep -E "android.permission.[A-Z_]+: granted=true"
```

Flag sensitive grants that look inconsistent: background location, camera, microphone, contacts, SMS, call log, body sensors, nearby devices, and all-files access (`MANAGE_EXTERNAL_STORAGE` via `cmd appops get PACKAGE MANAGE_EXTERNAL_STORAGE`).

AppOps output is not a complete substitute for Android's permission UI. Settings → Security & privacy → Privacy dashboard / Permission manager shows recent use clearly; suggest it to the user.

## Recommend

One app and one permission at a time, preferring the Settings path. Never revoke in bulk. Preserve accessibility, VPN, password-manager, device-management, and security tools unless the user explicitly asks to change one.
