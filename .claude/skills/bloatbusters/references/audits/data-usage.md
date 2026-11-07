# Audit: data usage

The easiest reliable view is Settings → Network & internet → SIMs/Mobile network → App data usage (path varies). Use it alongside ADB.

## Collect

```bash
adb -s SERIAL shell dumpsys netstats detail > SESSION/netstats.txt
wc -l SESSION/netstats.txt
grep -nE "^ *(Dev|Xt|Uid|UidTag) stats:" SESSION/netstats.txt
adb -s SERIAL shell pm list packages -U > SESSION/uids.txt               # package -> uid map
adb -s SERIAL shell dumpsys netpolicy | grep -iE "restrict background|uid=" | head -40
```

In the `Uid stats:` section, each `ident=[...] uid=N set=DEFAULT|FOREGROUND tag=0x0` header is followed by buckets with `rb=` (rx bytes) and `tb=` (tx bytes). `set=DEFAULT` is background traffic and `set=FOREGROUND` is foreground. The ident shows the network type: mobile = `type=0` or `MOBILE`; Wi-Fi = `type=1` or `WIFI`. To rank, sum `rb+tb` per uid/set/network with a small local `awk` script over the saved file, then map uids via `uids.txt`. Formats vary by version. If parsing is unreliable, say so and use the Settings view instead.

Shared UIDs (for example `1000` system, `1013` media) cover several components, so don't attribute them to a single app.

## Interpret and recommend

- Highlight apps with unexpectedly high **background mobile** data.
- Do not infer the content of encrypted traffic.
- Recommend per-app background data restriction for specific apps via Settings → Apps → APP → Mobile data & Wi-Fi → Background data, or in-app settings (auto-download, video quality, backup over mobile). Each needs user approval. Warn that restricting messaging or sync apps can delay messages.
