#!/bin/sh
# get-out-of-my-c-drive.sh -- move what Claude made for Corwin out of C:\Users\corwi, with an account of every step.
# Made 2026-11-08 for Corwin by Mentat (claude-opus-5-5), at his word (16:37: "build a script that moves anything claude made
# for me (vs things claudedesktop just does) out from my c:\ and keep careful accounting of the work as it goes: we can land a
# tar.gz of what we work with into /i/get-out-of-my-c-drive-claude-2026-11_NOv.tar.gz"). GPL-3.0-or-later.
# The spell that casts it: c4 spells/get-out-of-my-c-drive/SPELL.md.  Run from MSYS2/MINGW64 or Git Bash.
#
#   sh get-out-of-my-c-drive.sh inventory     write LIST: one line per top-level entry of C:\Users\corwi, first word the action
#   (read LIST; change "ask" to "move" or "keep" on any line; that is the only decision the script leaves to you)
#   sh get-out-of-my-c-drive.sh plan          say, in words, what apply would do; changes nothing
#   sh get-out-of-my-c-drive.sh apply         tar every "move" entry to TAR, verify it, copy each to its home on F:, verify
#                                             every file's sha256, and only then remove it from C:
#
# Actions in LIST:  move  (it goes)   ask  (you decide; apply skips it)   keep  (it stays; Claude Desktop's own, or yours)
# What counts as "Claude made it" is evidence, written beside each line, never a guess:
#   vibrobeast-state  the vibrobeast plugin's own state folder (its servers write ~/.mentcached; keys.py, prefs.py, ...)
#   named-in-N        the entry's path appears in N Claude session transcripts on this machine (it was touched; you judge made)
# Claude Desktop's own (.claude, .claude.json*, AppData, the Claude link) and your keys and shells are always keep.
# .mentcached moves only with ROOT_READY=yes: vibrobeast must already read its state from NEWROOT, and Claude must be closed.
set -u
CHOME=${CHOME:-/c/Users/corwi}
FHOME=${FHOME:-/f/claude}
DAY=${DAY:-$(date +%Y-%m-%d)}
DEST=${DEST:-$FHOME/_from-c-home/$DAY}
NEWROOT=${NEWROOT:-$FHOME/.mentcached}
TAR=${TAR:-/i/get-out-of-my-c-drive-claude-2026-11_NOv.tar.gz}
HERE=$(cd "$(dirname "$0")" && pwd)
LIST=${LIST:-$HERE/get-out-of-my-c-drive.list}
LEDGER=${LEDGER:-$HERE/get-out-of-my-c-drive.ledger}     # append-only: date, step, entry, result, detail (tab-separated)
ROOT_READY=${ROOT_READY:-no}
KEEP_ALWAYS='.claude .claude.json .claude.json.backup AppData Claude Application Data Local Settings NTUSER.DAT ntuser.dat.LOG1 ntuser.dat.LOG2 ntuser.ini .ssh .gnupg .aws .docker .bash_profile .bashrc .profile .zshrc .bash_history .gitconfig .authinfo Desktop Documents Downloads Pictures Videos Music Favorites Links Contacts Searches Saved Games OneDrive 3D Objects Cookies Recent SendTo Start Menu Templates NetHood PrintHood My Documents'
note() { printf '%s\t%s\t%s\t%s\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$1" "$2" "$3" "${4:-}" >> "$LEDGER"; }
say()  { echo "$*"; }
sha()  { sha256sum "$1" | cut -d' ' -f1; }
keep_always() { case " $KEEP_ALWAYS " in *" $1 "*) return 0;; esac; return 1; }
claude_running() { tasklist 2>/dev/null | grep -qi '^claude\.exe'; }

transcripts() {      # where Claude's sessions on this machine keep their transcripts
  for d in "$CHOME/AppData/Roaming/Claude/local-agent-mode-sessions" "$CHOME/AppData/Roaming/Claude/claude-code-sessions" "$CHOME/.claude/projects"; do
    [ -d "$d" ] && echo "$d"
  done
}

inventory() {
  [ -d "$CHOME" ] || { say "no $CHOME"; exit 2; }
  tlist=$(transcripts)
  : > "$LIST.new"
  ( cd "$CHOME" && ls -A ) | while IFS= read -r e; do
    if keep_always "$e"; then echo "keep	$e	Claude Desktop's own, or yours (always kept)" >> "$LIST.new"; continue; fi
    if [ "$e" = .mentcached ]; then echo "move	$e	vibrobeast-state (moves only with ROOT_READY=yes, to ${NEWROOT})" >> "$LIST.new"; continue; fi
    n=0
    if [ -n "$tlist" ]; then
      # both spellings a session writes: C:\\Users\\corwi\\NAME (JSON-escaped) and /c/Users/corwi/NAME
      n=$(echo "$tlist" | while IFS= read -r d; do grep -rlF -e "corwi\\\\$e" -e "corwi/$e" -e "mnt/corwi/$e" "$d" 2>/dev/null; done | sort -u | wc -l)
    fi
    if [ "$n" -gt 0 ]; then echo "ask	$e	named-in-$n session transcript(s); you judge whether Claude made it" >> "$LIST.new"
    else echo "keep	$e	no evidence Claude made it" >> "$LIST.new"; fi
  done
  [ -f "$LIST" ] && mv "$LIST" "$LIST.$(date +%Y%m%d%H%M%S)"
  mv "$LIST.new" "$LIST"
  note inventory - "$(grep -c . "$LIST") entries" "transcripts: $(echo "$tlist" | grep -c .)"
  say "wrote $LIST: $(grep -c '^move' "$LIST") move, $(grep -c '^ask' "$LIST") ask, $(grep -c '^keep' "$LIST") keep."
  say "Read it, change ask to move or keep, then: sh $0 plan"
}

home_of() { [ "$1" = .mentcached ] && echo "$NEWROOT" || echo "$DEST/$1"; }

entries() { grep '^move	' "$LIST" | cut -f2; }

plan() {
  [ -f "$LIST" ] || { say "no list yet: sh $0 inventory"; exit 2; }
  n=0
  entries | while IFS= read -r e; do
    if [ ! -e "$CHOME/$e" ]; then say "gone already: $e"; continue; fi
    if [ "$e" = .mentcached ] && [ "$ROOT_READY" != yes ]; then say "held: .mentcached (vibrobeast does not read $NEWROOT yet; ROOT_READY=yes when it does)"; continue; fi
    f=$(find "$CHOME/$e" -type f 2>/dev/null | wc -l); s=$(du -sh "$CHOME/$e" 2>/dev/null | cut -f1)
    say "move: $e ($f files, $s) -> $(home_of "$e")"
  done
  say "the tar: $TAR (everything above, as it stood on C:, before anything is removed)"
  say "asked and not answered: $(grep -c '^ask' "$LIST"); those stay where they are."
}

apply() {
  [ -f "$LIST" ] || { say "no list yet: sh $0 inventory"; exit 2; }
  if grep -q '^move	\.mentcached	' "$LIST" && [ "$ROOT_READY" = yes ] && claude_running; then
    say "Claude is running and would keep writing .mentcached: close Claude, then apply again"; exit 3; fi
  [ -d "$(dirname "$TAR")" ] && [ -w "$(dirname "$TAR")" ] || { say "cannot write $(dirname "$TAR"): is I: there?"; exit 3; }
  go=$(mktemp); trap 'rm -f "$go"' EXIT
  entries | while IFS= read -r e; do
    [ -e "$CHOME/$e" ] || continue
    [ "$e" = .mentcached ] && [ "$ROOT_READY" != yes ] && { note held "$e" "root not ready"; continue; }
    keep_always "$e" && { note refused "$e" "on the always-keep list"; continue; }
    echo "$e"
  done > "$go"
  [ -s "$go" ] || { say "nothing to move"; exit 0; }
  [ -e "$TAR" ] && { TAR="${TAR%.tar.gz}-$(date +%Y%m%d%H%M%S).tar.gz"; say "the first tar is already there; this run's: $TAR"; }
  note tar - started "$TAR"
  (cd "$CHOME" && tar czf "$TAR" -T "$go") || { note tar - FAILED; say "tar failed: nothing removed"; exit 4; }
  sha256sum "$TAR" > "$TAR.sha256"; tar tzvf "$TAR" > "$TAR.list"
  want=$(cd "$CHOME" && while IFS= read -r e; do find "$e" -type f; done < "$go" | wc -l)
  got=$(grep -c '^-' "$TAR.list")
  [ "$want" = "$got" ] || { note tar - "COUNT MISMATCH" "want $want got $got"; say "tar holds $got files, C: has $want: nothing removed"; exit 4; }
  note tar - ok "$(cut -d' ' -f1 "$TAR.sha256") files=$got"
  moved=0 left=0
  while IFS= read -r e; do
    to=$(home_of "$e"); bad=0
    (cd "$CHOME" && find "$e" -type f) | while IFS= read -r rel; do
      dst="$to${rel#$e}"; mkdir -p "$(dirname "$dst")"
      if [ -e "$dst" ] && [ "$(sha "$dst")" != "$(sha "$CHOME/$rel")" ]; then dst="$dst.from-c-$DAY"; fi
      cp -p "$CHOME/$rel" "$dst" && [ "$(sha "$dst")" = "$(sha "$CHOME/$rel")" ] || echo "BAD $rel"
    done > "$go.chk"
    if (cd "$CHOME" && find "$e" ! -type f ! -type d) | grep -q .; then echo "BAD holds links or devices" >> "$go.chk"; fi
    if grep -q '^BAD' "$go.chk"; then
      note copy "$e" "NOT VERIFIED" "$(grep -c '^BAD' "$go.chk") files; left on C:"; say "not verified, left on C: $e"; left=$((left+1))
    else
      rm -rf "${CHOME:?}/$e" && note moved "$e" ok "to $to" && say "moved: $e -> $to"; moved=$((moved+1))
    fi
  done < "$go"
  rm -f "$go.chk"
  note apply - done "moved=$moved left=$left"
  say "$moved moved, $left left on C: (see $LEDGER).  The tar: $TAR ($(cut -c1-12 "$TAR.sha256")...)"
}

case ${1:-} in
  inventory) inventory ;; plan) plan ;; apply) apply ;;
  *) sed -n '2,20p' "$0"; exit 1 ;;
esac
