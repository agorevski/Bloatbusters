# Audit: accounts and sync

Many accounts, abandoned accounts, and apps that sync data nobody uses cost battery, data, and privacy. Account names are personal data (email addresses, phone numbers). Report account **types and counts** only, never names.

## Collect

```bash
adb -s SERIAL shell dumpsys account > SESSION/account.txt
grep -oE "type=[A-Za-z0-9._]+" SESSION/account.txt | sort | uniq -c | sort -rn | head -20    # accounts per type
adb -s SERIAL shell dumpsys content > SESSION/content.txt
grep -iE "master sync|auto sync|sync_auto" SESSION/content.txt | head -5                     # global auto-sync state, if printed
grep -oE "authority=[A-Za-z0-9._]+" SESSION/content.txt | sort | uniq -c | sort -rn | head -20  # sync adapters by authority
```

Formats vary by version. If parsing is unreliable, say so and use Settings → Passwords & accounts (or Accounts) instead.

Map account types to apps: `com.google` = Google, `com.google.android.gm.exchange` / `com.android.exchange` = Exchange/Outlook mail, `com.whatsapp` = WhatsApp, `com.osp.app.signin` = Samsung account, `com.xiaomi` = Mi account. If unsure, say so rather than guess.

Cross-check with `audits/battery.md`: sync work shows up as `*sync*` wakelocks and jobs in batterystats.

## Interpret

- **Several accounts of the same type** (for example 3 Google accounts) is fine if the user uses them all. Ask.
- **Accounts for apps that are no longer installed or used** are cleanup candidates.
- **Sync adapters for data the user doesn't need on the phone** (for example contacts or calendar from a work account they no longer use) are candidates.
- Auto-sync off globally makes email and backups stale. Mention it if found, don't treat it as a problem.

## Recommend (Settings only)

- Remove stale accounts: Settings → Passwords & accounts → ACCOUNT → Remove account. Warn that removing an account deletes its synced data from the phone (not from the cloud). Removing the primary Google account also affects the Play Store, backups, Find My Device, and Factory Reset Protection. Never suggest removing the last Google account without spelling this out.
- Turn off sync for individual data types: Settings → Passwords & accounts → ACCOUNT → Account sync.
- Never add, remove, or change accounts or sync over ADB.
