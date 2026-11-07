# Undo / restore

Every Bloatbusters change has a rollback in `~/.bloatbusters/RO_SERIALNO/undo-steps.txt` (see `changes.md`). The user can always reverse everything without Claude:

```bash
~/.bloatbusters/RO_SERIALNO/undo.sh --dry-run   # preview, newest first
~/.bloatbusters/RO_SERIALNO/undo.sh             # confirm each step
~/.bloatbusters/RO_SERIALNO/undo.sh --yes       # one confirmation for all steps
```

The script finds the phone by `ro.serialno`, runs only recognized rollback commands, and appends `restore` entries to `changes.jsonl`. Steps restore recorded prior states, so re-running is safe.

## Guided undo (when the user wants to pick specific changes)

1. Read `~/.bloatbusters/RO_SERIALNO/changes.jsonl` and `undo-steps.txt`. If they do not exist, say so. Do not guess what Bloatbusters may have changed, and do not offer to enable every disabled package.
2. If an entry's `fingerprint` differs from the current build, warn that an OS update happened since the change.
3. Work out each change's net effect: the latest entry per target wins, and a later `restore` cancels it.
4. Check current state:

   | Type | Check |
   |---|---|
   | disable | `pm list packages -d \| grep -Fx "package:PACKAGE"` |
   | uninstall | `pm list packages \| grep -Fx "package:PACKAGE"` (absent = still uninstalled) |
   | appops | `cmd appops get PACKAGE OP` |
   | setting | `settings get NAMESPACE KEY` |
   | permission | `dumpsys package PACKAGE \| grep -F "PERMISSION:"` |

5. Show a numbered table (target, change, date, current state, rollback) and ask which to reverse.
6. Run each approved rollback from the log, one at a time. Verify it as in `changes.md`, then append a `"type":"restore"` entry to `changes.jsonl`.
7. If `cmd package install-existing` fails, the package must be reinstalled from its official source (Play Store or OEM store).

To undo everything, prefer `undo.sh`. The user can run it in their own terminal, or you can run it after they approve in chat. It still asks for confirmation, so pipe the answer: `echo y | ~/.bloatbusters/RO_SERIALNO/undo.sh --yes`.

## Full restore from a backup

If the user made a Bloatbusters backup (`backup.md`) and wants the phone back to that point, follow the restore section of `backup.md`. Run `undo.sh` first so package and setting changes are reversed before any media or APKs are restored.
