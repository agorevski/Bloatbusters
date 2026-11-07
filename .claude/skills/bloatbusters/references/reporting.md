# Presenting findings and proposed changes

Keep the report concise and actionable. Prioritize high-confidence, low-risk items. Separate observations from recommendations. Do not pad with speculative tweaks.

## Device

| | |
|---|---|
| Manufacturer / model | |
| Android version (SDK) | |
| Build | |
| ADB target | serial |
| Audit limitations | unsupported commands, restricted data, short history windows |

## Findings

One row or short block per finding:

- **Finding:** what was observed.
- **Evidence:** command and the relevant result, plus the time window (for example "batterystats since last full charge, about 14h").
- **Impact:** battery, storage, memory, notifications, reliability, privacy, data, or performance.
- **Confidence:** high / medium / low.
- **Recommendation:** a specific next step, or "no action, informational".

Quote only redacted, minimal excerpts. Prefer counts and package names over raw output.

## Proposed changes

Number every change so the user can approve items individually. For each:

| # | Target | Action / command | Benefit and trade-off | Risk | Rollback | Reboot / user step |
|---|---|---|---|---|---|---|
| 1 | `com.example.app` | `pm disable-user --user 0 com.example.app` | ... | low | `pm enable --user 0 com.example.app` | none |

- Settings-app steps count as changes too. List the exact Settings path.
- Mark anything that touches a package from the protected-state snapshot as **not recommended**. Include it only if the user asked for it specifically.
- Mark approval-only maintenance commands (`changes.md`) as **not undoable** in the Risk column, and write "none: not undoable" plus what is lost in the Rollback column.
- If §3 found the device ID unusable, or the current user is not 0, list only Settings-app steps and explain why.
- End with a direct question: "Which of these should I apply? Reply with numbers, or 'none'."

## Final summary (after applying)

- What changed (with change-log entries), what was skipped, and anything that failed.
- Rollback commands for each change.
- What to observe and for how long (for example "compare overnight battery drain over 2–3 similar nights"), and when a follow-up check (`audits/follow-up.md`) would be useful, for example after the next OS update.
- That a numbers-only line was added to `~/.bloatbusters/RO_SERIALNO/metrics.jsonl`.
- The reminder to turn off USB/Wireless debugging once the phone has worked normally for a while (SKILL.md §4).
