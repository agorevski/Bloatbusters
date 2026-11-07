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
- End with a direct question: "Which of these should I apply? Reply with numbers, or 'none'."

## Final summary (after applying)

- What changed (with change-log entries), what was skipped, and anything that failed.
- Rollback commands for each change.
- What to observe and for how long (for example "compare overnight battery drain over 2–3 similar nights").
