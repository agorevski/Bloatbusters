# Bloatbusters

![Bloatbusters logo](images/bloatbusters.jpg)

**I Ain't Fraid of No Bloat!**

Bloatbusters is a [Claude Code](https://claude.com/claude-code) skill that audits and tunes an Android phone over [ADB](https://developer.android.com/tools/adb). It inspects the phone read-only, explains what it finds, and changes only what you approve. **Every change can be undone with one local script.** No root is required.

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

Pick one or more goals: **battery life**, **unused apps**, **RAM**, **storage**, **notifications**, **performance**, **crashes and background errors**, **privacy and permissions**, **data usage**, **connectivity / Android Auto**, **fewer distractions**, a **full tune-up**, **back up my phone**, **undo**, or describe your own problem.

Each session follows the same steps: **ask your goal → inspect read-only → report findings → you approve specific changes → apply → verify.**

## Undo anything

Before each change, Bloatbusters writes its rollback command to a per-phone folder on your computer:

```text
~/.bloatbusters/<phone-serial>/
├── undo.sh          # reverses every recorded change, newest first
├── undo-steps.txt   # one rollback command per change
└── changes.jsonl    # audit trail of changes and restores
```

```bash
~/.bloatbusters/<phone-serial>/undo.sh --dry-run   # preview
~/.bloatbusters/<phone-serial>/undo.sh             # confirm each step
~/.bloatbusters/<phone-serial>/undo.sh --yes       # confirm once, undo all
```

The script only runs recognized rollback commands, only against the matching phone, and is safe to re-run. Changes that can't be undone this way are never made over ADB. For those, Bloatbusters walks you through Android Settings instead.

## Optional backup

Choose **back up my phone** (also offered before the first change) to copy media and files, app installers, and a device snapshot to a folder you pick. Bloatbusters can then do a guided restore from it. ADB can't back up app data, messages, or authenticator codes; the skill tells you which official backup tool covers each.

## Safety rules

- Read-only until you approve specific, numbered changes. "Clean everything" is not approval.
- Core components are off limits: telephony, System UI, Play services, your launcher, keyboard, accessibility services, and device management.
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
│   └── backup.md         # Local backup and full restore
└── scripts/
    └── undo.sh           # Undo runner template, copied per phone
```

Only `SKILL.md` loads when the skill starts. Each reference loads only when its step or goal is needed.

## Caveats

Diagnostics vary by Android version and manufacturer. Some data (usage history, per-app battery, notification history) may be incomplete or restricted, and the skill says so rather than guessing.

---

*Hunting down rogue apps, battery vampires, notification gremlins, and digital dead weight.*
