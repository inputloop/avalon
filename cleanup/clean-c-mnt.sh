#!/bin/sh
# clean-c-mnt.sh -- tidy the stray C:\Users\corwi\mnt tree that sessions wrote by mistake.
# Made 2026-11-08 for Corwin by Mentat (claude-opus-5-5), at his word (08:32: "make a script to clean up things under your /mnt back
# on my c drive"). GPL-3.0-or-later.
#
# Every file under STRAY (default /c/Users/corwi/mnt) is matched to its home under F:\claude:
#   mnt/c4/PATH     -> /f/claude/c4/PATH
#   mnt/claude/PATH -> /f/claude/PATH
# If the home copy exists with the same sha256, the stray file is removed.
# If the home copy is missing or differs, the stray file is first copied to KEEP (default /f/claude/_from-c-mnt/<date>/PATH),
# the copy is hashed against the stray, and only then is the stray removed.  Nothing on F: is overwritten.  Empty folders go last.
#
# Dry run by default: it says what it would do.  Run with --apply to do it.  Run from MSYS2/MINGW64 or Git Bash.
set -u
STRAY=${STRAY:-/c/Users/corwi/mnt}
FHOME=${FHOME:-/f/claude}
KEEP=${KEEP:-$FHOME/_from-c-mnt/$(date +%Y-%m-%d)}
apply=no; [ "${1:-}" = --apply ] && apply=yes
[ -d "$STRAY" ] || { echo "nothing at $STRAY: done"; exit 0; }
same=0 kept=0 bad=0
tmp=$(mktemp); trap 'rm -f "$tmp"' EXIT
(cd "$STRAY" && find . -type f) | sed 's#^\./##' > "$tmp"
while IFS= read -r rel; do
  case $rel in
    c4/*)     home=$FHOME/c4/${rel#c4/} ;;
    claude/*) home=$FHOME/${rel#claude/} ;;
    *)        home= ;;
  esac
  s=$(sha256sum "$STRAY/$rel" | cut -d' ' -f1)
  if [ -n "$home" ] && [ -f "$home" ] && [ "$(sha256sum "$home" | cut -d' ' -f1)" = "$s" ]; then
    echo "same as F:  remove  $rel"
    same=$((same+1)); [ $apply = yes ] && rm -f "$STRAY/$rel"
  else
    why="differs from F:"; [ -n "$home" ] && [ ! -f "$home" ] && why="not on F:"; [ -z "$home" ] && why="no home rule"
    echo "$why  keep -> ${KEEP#$FHOME/}/$rel, then remove"
    kept=$((kept+1))
    if [ $apply = yes ]; then
      mkdir -p "$(dirname "$KEEP/$rel")" && cp -p "$STRAY/$rel" "$KEEP/$rel" &&
      [ "$(sha256sum "$KEEP/$rel" | cut -d' ' -f1)" = "$s" ] && rm -f "$STRAY/$rel" ||
      { echo "  COPY NOT VERIFIED: left in place: $rel"; bad=$((bad+1)); }
    fi
  fi
done < "$tmp"
if [ $apply = yes ]; then
  find "$STRAY" -depth -type d -empty -exec rmdir {} \; 2>/dev/null
  [ -d "$STRAY" ] && echo "left in $STRAY:" && (cd "$STRAY" && find . | head)
fi
echo "$same same as F: (removed$([ $apply = yes ] || echo ' on --apply')), $kept kept under ${KEEP#$FHOME/}$([ $apply = yes ] || echo ' on --apply'), $bad not verified"
[ $apply = yes ] || echo "dry run: nothing changed.  Run again with --apply."
