#!/bin/sh
# prove-red-get-out.sh -- get-out-of-my-c-drive.sh on a fake home, green, then three planted faults that must each go red.
# Mentat (for Corwin, claude-opus-5-5), 2026-11-08. GPL-3.0-or-later.
set -u
S=$(cd "$(dirname "$0")" && pwd)/get-out-of-my-c-drive.sh
W=$(mktemp -d); trap 'rm -rf "$W"' EXIT
fresh() { rm -rf "$W/t"; mkdir -p "$W/t/c/.claude/projects/p" "$W/t/c/tmp/a" "$W/t/f" "$W/t/i"
  echo t > "$W/t/c/tmp/a/x.txt"; ln -s x.txt "$W/t/c/tmp/a/l" 2>/dev/null; mkdir -p "$W/t/c/out2"; echo o > "$W/t/c/out2/o"
  printf '%s\n' '"C:\\Users\\corwi\\tmp" "/c/Users/corwi/out2" "/c/Users/corwi/.ssh"' > "$W/t/c/.claude/projects/p/s.jsonl"; mkdir -p "$W/t/c/.ssh"; echo s > "$W/t/c/.ssh/k"
  export CHOME="$W/t/c" FHOME="$W/t/f" TAR="$W/t/i/o.tar.gz" LIST="$W/t/list" LEDGER="$W/t/ledger" DAY=d
  sh "$1" inventory >/dev/null; sed -i 's/^ask\t/move\t/; s/^keep\t\.ssh/move\t.ssh/' "$LIST"; sh "$1" apply >/dev/null 2>&1; }
ok=0 bad=0
check() { if eval "$2"; then echo "  held: $1"; ok=$((ok+1)); else echo "  FAILED: $1"; bad=$((bad+1)); fi; }
echo "control (the script as it ships):"
fresh "$S"
check "out2 moved and verified"            '[ ! -e "$CHOME/out2" ] && [ -f "$FHOME/_from-c-home/d/out2/o" ]'
check "tmp (holds a link) left on C:"      '[ -f "$CHOME/tmp/a/x.txt" ]'
check ".ssh refused although marked move"  '[ -f "$CHOME/.ssh/k" ] && grep -q "refused	.ssh" "$LEDGER"'
check "the tar holds what moved"           'tar tzf "$TAR" | grep -q out2/o'
plant() { sed "$2" "$S" > "$W/p.sh"; fresh "$W/p.sh"
  if eval "$3"; then echo "  caught: $1"; ok=$((ok+1)); else echo "  MISSED: $1"; bad=$((bad+1)); fi; }
echo "planted faults (each must turn its check red):"
plant "a copy that is never verified"     's/\[ "$(sha "$dst")" = "$(sha "$CHOME\/$rel")" \]/true/; s/cp -p "$CHOME\/$rel" "$dst"/: > "$dst"/' '[ ! -s "$FHOME/_from-c-home/d/out2/o" ] && [ ! -e "$CHOME/out2" ]'
plant "the always-keep list ignored"      's/keep_always "$e" && { note refused/false \&\& { note refused/' '[ ! -e "$CHOME/.ssh/k" ]'
plant "links no longer hold an entry"     's/! -type f ! -type d) | grep -q \./! -type f ! -type d) | grep -q NEVERMATCH/' '[ ! -e "$CHOME/tmp" ]'
echo "$ok held or caught, $bad not"; [ $bad = 0 ] && echo "PROVE-RED OK" || { echo "PROVE-RED FAILED"; exit 1; }
