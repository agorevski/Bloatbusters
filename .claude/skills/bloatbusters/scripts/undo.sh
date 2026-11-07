#!/usr/bin/env bash
# Bloatbusters undo runner.
#
# Lives in ~/.bloatbusters/<ro.serialno>/ next to undo-steps.txt and reverses
# every recorded Bloatbusters change on that phone, newest first. Every step
# restores a recorded prior state, so running it more than once is safe.
#
# Usage: ./undo.sh [--dry-run] [--yes]
#   --dry-run  list the steps without running anything
#   --yes      run all steps after a single confirmation instead of asking per step

set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
STEPS="$DIR/undo-steps.txt"
LOG="$DIR/changes.jsonl"
DEVICE_ID="$(basename "$DIR")"

DRY_RUN=0
ASSUME_YES=0
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --yes) ASSUME_YES=1 ;;
    *) echo "Unknown option: $arg" >&2; exit 2 ;;
  esac
done

# Only these rollback forms are ever executed. Anything else in the steps file
# is reported and skipped, never run.
PKG='[A-Za-z0-9_]+(\.[A-Za-z0-9_]+)+'
FORMS=(
  "pm enable --user 0 $PKG"
  "pm disable-user --user 0 $PKG"
  "cmd package install-existing --user 0 $PKG"
  "pm uninstall --user 0 $PKG"
  "cmd appops set $PKG [A-Z_]+ (allow|ignore|deny|default|foreground)"
  "settings put (system|secure|global) [A-Za-z0-9_.]+ [A-Za-z0-9_.:,/+-]+"
  "settings delete (system|secure|global) [A-Za-z0-9_.]+"
  "pm grant $PKG [A-Za-z0-9_.]+"
  "dumpsys deviceidle whitelist [+]$PKG"
  "cmd netpolicy remove restrict-background-(blacklist|denylist) [0-9]+"
  "cmd uimode night (yes|no|auto)"
  "cmd role add-role-holder --user 0 android\.app\.role\.HOME $PKG"
)
ALLOWED="^($(IFS='|'; echo "${FORMS[*]}"))$"

# The directory name is the phone's ro.serialno. Refuse names that are not a
# real serial, such as the state root itself or a placeholder.
if ! [[ "$DEVICE_ID" =~ ^[A-Za-z0-9._-]+$ ]] || [[ "$DEVICE_ID" =~ ^(\.bloatbusters|unknown|\.+)$ ]]; then
  echo "Unexpected device directory name: $DEVICE_ID" >&2; exit 1
fi
if [ ! -s "$STEPS" ]; then
  echo "No recorded changes in $STEPS. Nothing to undo."; exit 0
fi
command -v adb >/dev/null || { echo "adb not found on PATH." >&2; exit 1; }

# Find the attached device whose ro.serialno matches this directory.
SERIAL=""
while read -r s state _; do
  [ "$state" = "device" ] || continue
  sn="$(adb -s "$s" shell getprop ro.serialno </dev/null | tr -d '\r')"
  if [ "$sn" = "$DEVICE_ID" ]; then SERIAL="$s"; break; fi
done < <(adb devices | tail -n +2)

if [ -z "$SERIAL" ] && [ "$DRY_RUN" -eq 0 ]; then
  echo "Phone $DEVICE_ID is not attached (or not authorized). Connect it and retry." >&2; exit 1
fi

# Steps file format: TIMESTAMP<TAB>DEVICE-SHELL-COMMAND, one per line, oldest first.
reversed() { awk '!/^#/ && NF {a[++n]=$0} END {for (i=n; i>0; i--) print a[i]}' "$STEPS"; }

total="$(reversed | wc -l | tr -d ' ')"
echo "Bloatbusters undo for phone $DEVICE_ID${SERIAL:+ (adb serial $SERIAL)}: $total step(s), newest first."

if [ "$DRY_RUN" -eq 0 ] && [ "$ASSUME_YES" -eq 1 ]; then
  read -r -p "Run all $total steps? [y/N] " ans || ans=""
  [[ "$ans" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }
fi

ok=0; failed=0; skipped=0; i=0
while IFS=$'\t' read -r ts cmd <&3; do
  i=$((i + 1))
  echo
  echo "[$i/$total] recorded $ts"
  echo "    adb -s ${SERIAL:-SERIAL} shell $cmd"
  if ! [[ "$cmd" =~ $ALLOWED ]]; then
    echo "    SKIPPED: not a recognized rollback command. Review it manually."
    skipped=$((skipped + 1)); continue
  fi
  [ "$DRY_RUN" -eq 1 ] && continue
  # Uninstalling a user-installed app would delete it and its data. Only allow
  # this rollback for packages that are part of the system image.
  if [[ "$cmd" == "pm uninstall "* ]]; then
    pkg="${cmd##* }"
    if ! adb -s "$SERIAL" shell pm list packages -s -u </dev/null | tr -d '\r' | grep -qFx "package:$pkg"; then
      echo "    SKIPPED: $pkg is not a system-image package, so uninstalling it would delete it. Review it manually."
      skipped=$((skipped + 1)); continue
    fi
  fi
  if [ "$ASSUME_YES" -eq 0 ]; then
    read -r -p "    Run this step? [y/N] " ans || ans=""
    if ! [[ "$ans" =~ ^[Yy]$ ]]; then skipped=$((skipped + 1)); continue; fi
  fi
  # Validated above: no quotes or shell metacharacters, so word splitting is safe.
  # shellcheck disable=SC2086
  if out="$(adb -s "$SERIAL" shell $cmd </dev/null 2>&1)" && ! grep -qiE "exception|error|failure|unknown" <<<"$out"; then
    result="ok"; ok=$((ok + 1))
  else
    result="failed"; failed=$((failed + 1))
  fi
  echo "    $result: ${out//$'\n'/ }"
  printf '{"ts":"%s","device":"%s","type":"restore","source":"undo.sh","command":"%s","result":"%s"}\n' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$DEVICE_ID" "$cmd" "$result" >> "$LOG"
done 3< <(reversed)

echo
if [ "$DRY_RUN" -eq 1 ]; then
  echo "Dry run: nothing was changed. $skipped step(s) would be skipped as unrecognized."
else
  echo "Done: $ok restored, $failed failed, $skipped skipped."
  [ "$failed" -eq 0 ] || exit 1
fi
