# Bloatbusters

![Bloatbusters logo](images/bloatbusters.jpg)

**I Ain't Fraid of No Bloat!**

Bloatbusters is a [Claude Code](https://claude.com/claude-code) skill that audits and tunes an Android phone or tablet over [ADB](https://developer.android.com/tools/adb). It inspects the phone read-only, explains what it finds, and changes only what you approve. **Every change can be undone with one local script**, apart from a few maintenance commands that are [listed explicitly](#commands-that-cant-be-undone) and never run without their own approval. No root is required.

## Quick start

1. **Install ADB:** `brew install --cask android-platform-tools` (macOS), `winget install Google.PlatformTools` (Windows), or your distro's `adb`/`android-tools` package (Linux).
2. **Prepare the phone:** Settings → About phone → tap **Build number** 7 times, then turn on Developer options → **USB debugging**. Connect, unlock, and accept the authorization prompt.
3. **Check the connection:** `adb devices -l` should list your phone as `device`.
4. **Run it:**
   ```bash
   git clone <this-repo-url> bloatbusters
   cd bloatbusters
   claude
   ```
   Then type `/bloatbusters`, or describe a problem such as "my battery drains overnight."

Stuck on step 1–3? Run `/bloatbusters` anyway. It walks through installation, wireless debugging, and connection errors (`unauthorized`, `offline`, Linux permissions).

To use it from any directory: `cp -R .claude/skills/bloatbusters ~/.claude/skills/`

## What it can do

Pick one or more goals: **battery life**, **unused apps**, **RAM**, **storage**, **notifications**, **performance**, **crashes and background errors**, **privacy and permissions**, **data usage**, **connectivity / Android Auto**, **fewer distractions**, **pop-up ads and suspicious apps**, **security check-up**, **accounts and sync**, a **faster or simpler home screen** (including switching to a maintained lightweight launcher), **setting up a phone or tablet for a child** (Family Link, Samsung Kids, purchase and sideloading lockdown, family DNS filtering), a **full tune-up**, a **follow-up check** on earlier changes, **back up my phone**, **undo**, or describe your own problem.

Each session follows the same steps: **ask your goal → inspect read-only → report findings → you approve specific changes → apply → verify.** Each session also saves a numbers-only snapshot (battery drain, free storage, crash counts, and so on), so a later follow-up can show whether things improved and whether an OS update reverted anything.

## Undo anything

Before each change, Bloatbusters writes its rollback command to a per-phone folder on your computer:

```text
~/.bloatbusters/<phone-serial>/
├── undo.sh          # reverses every recorded change, newest first
├── undo-steps.txt   # one rollback command per change
├── changes.jsonl    # audit trail of changes, maintenance runs, and restores
└── metrics.jsonl    # numbers-only measurements per session, for follow-ups
```

```bash
~/.bloatbusters/<phone-serial>/undo.sh --dry-run   # preview
~/.bloatbusters/<phone-serial>/undo.sh             # confirm each step
~/.bloatbusters/<phone-serial>/undo.sh --yes       # confirm once, undo all
```

The script only runs recognized rollback commands, only against the matching phone, and is safe to re-run. It will never uninstall an app you installed yourself. Changes that can't be undone this way are never made over ADB. For those, Bloatbusters walks you through Android Settings instead.

If a change breaks something (missing home screen, boot loop), keep the phone connected and run `undo.sh`. The skill's recovery guide covers boot loops, Android's "Rescue Party" recovery screen (choose **Try again**, never **Factory data reset**), and safe mode.

### Commands that can't be undone

A few maintenance commands can't be reversed by `undo.sh`. Each one triggers a job Android already runs on its own, and none of them changes settings, app states, or your data. Bloatbusters proposes them only for a matching problem, labels each one **not undoable**, explains what is lost, and runs it only after you approve that specific item. They are logged in `changes.jsonl` but not in `undo-steps.txt`.

| Command | What it does | What can't be undone |
|---|---|---|
| `pm trim-caches` | Clears app caches across all apps | Apps rebuild their caches; some re-download offline content |
| `sm fstrim` | Runs storage TRIM now | Nothing visible |
| `cmd package bg-dexopt-job` | Runs app optimization now instead of overnight | Takes minutes and some battery |
| `reboot` | Restarts the phone | Unsaved work in open apps |

The complete list and the rules for using it are in [`references/changes.md`](.claude/skills/bloatbusters/references/changes.md#approval-only-maintenance-commands-not-undoable). Nothing outside that list may skip the undo script.

## Optional backup

Choose **back up my phone** (also offered before the first change) to copy media and files, app installers, and a device snapshot to a folder you pick. Bloatbusters can then do a guided restore from it. ADB can't back up app data, messages, or authenticator codes; the skill tells you which official backup tool covers each.

## Safety rules

- Read-only until you approve specific, numbered changes. "Clean everything" is not approval.
- Core components are off limits: telephony, System UI, Play services, your launcher (and the stock launcher, even after you switch), keyboard, accessibility services, password-manager autofill, default apps, VPN, companion apps for paired devices, and device management.
- Only the main user profile is changed. Work profiles, Secure Folder, and Dual Apps are left alone.
- Prefers Settings changes and disabling apps over uninstalling. No root, no bulk removal scripts, no clearing app data, no force-stop "RAM boosters."
- Raw device output stays in a temporary local folder. Personal data is redacted from anything shown, and nothing is uploaded.
- No promised battery or speed gains without measurements to back them up.

## Repository layout

```text
.claude/skills/bloatbusters/
├── SKILL.md              # Core workflow and safety rules (always loaded)
├── references/
│   ├── setup.md          # Installing ADB and fixing connection problems
│   ├── audits/           # One read-only audit procedure per goal
│   ├── reporting.md      # Findings and proposed-change format
│   ├── changes.md        # Applying, verifying, and logging changes
│   ├── undo.md           # Undo and restore
│   ├── recovery.md       # What to do if a change breaks something
│   └── backup.md         # Local backup and full restore
└── scripts/
    └── undo.sh           # Undo runner template, copied per phone
```

Only `SKILL.md` loads when the skill starts. Each reference loads only when its step or goal is needed.

## Caveats

Diagnostics vary by Android version and manufacturer. Some data (usage history, per-app battery, notification history) may be incomplete or restricted, and the skill says so rather than guessing.

---

*Hunting down rogue apps, battery vampires, notification gremlins, and digital dead weight.*
