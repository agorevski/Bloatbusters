# Audit: follow-up check and measurement baseline

Use this when the user comes back after an earlier Bloatbusters session, after an OS update, or to see whether changes helped. It also defines the `metrics.jsonl` line that every session records (SKILL.md §4).

## 1. Did the earlier changes hold?

OS updates and OEM "repair" jobs can re-enable disabled packages, reinstall removed ones, or reset settings.

1. Read `~/.bloatbusters/RO_SERIALNO/changes.jsonl`. Work out each target's net state as in `undo.md`: the latest entry per target wins, and a later `restore` cancels it. Ignore `maintenance` entries.
2. Compare each entry's `fingerprint` with the current `ro.build.fingerprint`. If it differs, an OS update happened since then. Say so.
3. Check the current state of each change that is still in effect, with the checks in the `undo.md` table.
4. Report a table: target, change, date, expected state, current state, and whether it **held**, was **reverted** (by an update, the OEM, or the user), or **no longer applies** (package gone).

For reverted changes, ask whether the user still wants them. Re-applying one is a new change: approval, a new undo step, apply, verify, and log, as in `changes.md`. Never re-apply automatically. The user may have reversed it on purpose.

If `changes.jsonl` has an `install` entry (a launcher installed over ADB), compare its installed `versionName` with the latest release on its source page. It doesn't update itself.

Also look for **new** bloat since the last session: packages that are new since the update (`pm list packages -s` compared with the backup snapshot, if there is one), and new notification-heavy or battery-heavy apps.

## 2. Did things improve?

Read `~/.bloatbusters/RO_SERIALNO/metrics.jsonl` and compare the most recent earlier line with fresh numbers from today. Only compare like with like: similar batterystats windows, similar usage. Batterystats resets at each full charge, so a short window (under ~6 hours) is not comparable. Say so instead of guessing.

Report changes as observations ("screen-off drain went from about X to about Y mAh per hour over similar windows"), not proof that a specific change caused them.

## Metrics line format

Append one line per session, after the audit. Numbers only: no package names, account names, SSIDs, or anything personal. Use `null` for anything not measured this session.

```bash
mkdir -p -m 700 ~/.bloatbusters/RO_SERIALNO
printf '%s\n' '{"ts":"2026-01-01T12:00:00Z","fingerprint":"BUILD_FINGERPRINT","sdk":34,"uptime_h":52,"data_free_pct":23,"battery_level":81,"batterystats_window_h":14.2,"discharge_mah":1650,"screen_off_discharge_mah":420,"screen_off_h":9.5,"crash_buffer_entries":3,"anr_events":0,"lowmem_kills":12,"third_party_apps":87,"disabled_packages":14,"notification_records":210}' >> ~/.bloatbusters/RO_SERIALNO/metrics.jsonl
chmod 600 ~/.bloatbusters/RO_SERIALNO/metrics.jsonl
```

Where each number comes from:

| Field | Source |
|---|---|
| `uptime_h`, `data_free_pct`, `battery_level`, `sdk` | SKILL.md §3 baseline |
| `batterystats_window_h`, `discharge_mah`, `screen_off_discharge_mah`, `screen_off_h` | `audits/battery.md` (discharge lines in batterystats) |
| `crash_buffer_entries`, `anr_events` | `audits/errors.md` (count of crash-buffer entries, `am_anr` events) |
| `lowmem_kills` | `audits/memory.md` (`am_kill`/`am_low_memory` count) |
| `third_party_apps`, `disabled_packages` | `pm list packages -3 \| wc -l`, `pm list packages -d \| wc -l` |
| `notification_records` | `audits/notifications.md` (total `pkg=` matches) |

Collect only what the session's audits already produced. Don't run extra audits just to fill fields. Never edit or delete earlier lines.
