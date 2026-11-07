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
adb -s SERIAL shell cmd appops query-op WRITE_SETTINGS allow               # modify system settings
adb -s SERIAL shell cmd appops query-op SCHEDULE_EXACT_ALARM allow         # Android 12+
adb -s SERIAL shell cmd appops query-op USE_FULL_SCREEN_INTENT allow       # Android 14+: full-screen pop-ups
adb -s SERIAL shell settings get secure enabled_notification_policy_access_packages   # Do Not Disturb access
adb -s SERIAL shell dumpsys deviceidle whitelist | grep "^user,"           # battery-optimization exemptions the user granted
```

`query-op` support varies by version. If it errors, fall back to `cmd appops get PACKAGE` per candidate.

Accessibility services, notification listeners, and device admins can read screen content or notifications. An unexpected one is a high-priority finding. Before calling it unexpected, check whether it belongs to a password manager, VPN, MDM, or other tool the user relies on. Overlay, full-screen intent, and "modify system settings" access in an unrecognized app is a common adware pattern (`audits/adware.md`).

**User-installed certificates** can let someone read encrypted traffic. ADB can't list them reliably. Ask the user to check Settings → Security & privacy → More security settings → Encryption & credentials → User credentials (and Trusted credentials → User tab). Anything there that isn't from their employer's MDM or a tool they installed deliberately is a high-priority finding.

**Saved Wi-Fi networks** (Android 11+; SSIDs are personal, so report counts only):
```bash
adb -s SERIAL shell cmd wifi list-networks > SESSION/wifi_networks.txt
tail -n +2 SESSION/wifi_networks.txt | wc -l                    # saved networks
grep -ciE "[[:space:]]open([[:space:]]|$)" SESSION/wifi_networks.txt   # open (unencrypted) networks the phone auto-joins
```
Old open networks (cafés, hotels, airports) let anyone with the same network name lure the phone onto their network. Recommend forgetting the ones the user no longer uses: Settings → Network & internet → Internet → Saved networks. Don't forget networks over ADB; it isn't undoable.

**Private DNS:**
```bash
adb -s SERIAL shell 'settings get global private_dns_mode; settings get global private_dns_specifier'
```
`null` or `opportunistic` = Automatic (encrypted DNS when the network supports it). `hostname` = a specific DNS-over-TLS provider. `off` = plain DNS.

## Runtime permissions, per app

```bash
adb -s SERIAL shell pm list packages -3 > SESSION/third_party.txt
adb -s SERIAL shell dumpsys package PACKAGE | grep -E "android.permission.[A-Z_]+: granted=true"
```

Flag sensitive grants that look inconsistent: background location, camera, microphone, contacts, SMS, call log, body sensors, nearby devices, and all-files access (`MANAGE_EXTERNAL_STORAGE` via `cmd appops get PACKAGE MANAGE_EXTERNAL_STORAGE`).

AppOps output is not a complete substitute for Android's permission UI. Settings → Security & privacy → Privacy dashboard / Permission manager shows recent use clearly; suggest it to the user.

## Recommend

One app and one permission at a time, preferring the Settings path. Never revoke in bulk. Preserve accessibility, VPN, password-manager, device-management, and security tools unless the user explicitly asks to change one.

**Private DNS with a filtering resolver** is the biggest single lever against ads and trackers across all apps and browsers. Offer it as an option, not a default:

- Choices: an ad- and tracker-blocking resolver (for example AdGuard DNS, `dns.adguard-dns.com`, or a personal NextDNS profile hostname), or a privacy resolver without filtering (for example Cloudflare, `one.one.one.one`). The user picks. Don't push a provider.
- Trade-offs: the provider sees every domain the phone looks up. Blocking can break some sites, links in emails, or in-app purchases. Some captive portals (hotels, planes) and work VPNs fail until it's set back to Automatic. Hotspot clients are not covered.
- Apply via Settings → Network & internet → Private DNS (simplest for the user to reverse), or over ADB after approval: set `private_dns_specifier`, then `private_dns_mode` to `hostname` (`changes.md` settings table; two undo steps).
- Verify: `adb -s SERIAL shell dumpsys connectivity | grep -iE "PrivateDns|private dns" | head -5` should show the hostname as validated. Then ask the user to load a website and an app. If validation fails, roll both settings back immediately.
