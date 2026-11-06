#!/usr/bin/bash
# drop - the outward counterpart of lift: promoted tool -> a friend's stage.
# DRAFT - keeper's ruling pending (see STAGE-NOTES.md, open question 1).
#
# Lift's gates protect US from what comes in (provenance). A drop's gates
# protect THEM from what goes out (selection): does this artifact carry a
# case, a host, a person? So drop asks a different question at the door.
#
# Gates, in order (each a hard PARK):
#   1. promoted - the artifact must already live in tools/ or utils/. A drop
#                 is NOT a side door around the review queue. (Lowering this
#                 is the keeper's call, on the record, with -f.)
#   2. sig      - detached .asc verifies vs keys/ (what the friend will check)
#   3. dialect  - path-lint -s: no host paths, no scratch paths ride outward
#   4. NO4C     - raised parks; mentioned notes (same ruling as lift)
#   5. model    - AVALON.md ships with every drop, unasked: a recipient who
#                 gets tools without the model gets capability without law.
#   6. receipt  - sha256 manifest at the destination + permanent receipt
set -u
me=$(basename "$0")
proj=$(cd "$(dirname "$0")/.." && pwd)
lint=$proj/tools/path-lint.sh
model=$proj/AVALON.md
force= ; if test "${1:-}" = "-f" ; then force=1 ; shift ; fi
test $# -ge 2 || { echo "Usage: $me [-f] DEST_DIR FILE..." ; exit 2 ; }
dest=$1 ; shift
mkdir -p "$dest" || { echo "$me: cannot make dest: $dest" ; exit 3 ; }

export GNUPGHOME=$(mktemp -d) ; chmod 700 "$GNUPGHOME"
trap 'rm -rf "$GNUPGHOME"' EXIT
gpg -q --import "$proj"/keys/*.asc 2>/dev/null || { echo "no keys in $proj/keys" ; exit 3 ; }

rc=0
for f in "$@" ; do
  b=$(basename "$f")
  case $(cd "$(dirname "$f")" && pwd) in
    "$proj"/tools|"$proj"/utils) : ;;
    *) if test -z "$force" ; then
         echo "PARK $b: not promoted (tools/ or utils/ only) - the queue is not a side door"
         rc=1 ; continue
       else echo "NOTE $b: unpromoted, dropped under keeper override (-f)" ; fi ;;
  esac
  test -r "$f.asc" || { echo "PARK $b: no detached sig (a friend cannot check what is not signed)" ; rc=1 ; continue ; }
  gpg --verify "$f.asc" "$f" 2>&1 | grep -q 'Good signature' \
    || { echo "PARK $b: signature does not verify vs pinned keys" ; rc=1 ; continue ; }
  "$lint" -s "$f" >/dev/null \
    || { echo "PARK $b: path-lint -s failed (a host path must not ride outward)" ; rc=1 ; continue ; }
  if grep -Eq '^[[:space:]]*#?N[O0]4C([[:space:]]|\]|$)' "$f" && test -z "$force" ; then
    echo "PARK $b: NO4C raised - keeper lowers with -f" ; rc=1 ; continue
  elif grep -Eq 'N[O0]4C' "$f" ; then
    echo "NOTE $b: NO4C mentioned (not raised) - dropping"
  fi
  cp "$f" "$f.asc" "$dest"/ || { echo "FAIL $b: copy" ; rc=1 ; continue ; }
  echo "DROPPED $b -> $dest"
done

# 5. the model always travels with the tools
if test "$rc" = 0 ; then
  if test -r "$model" ; then
    cp "$model" "$dest"/ ; test -r "$model.asc" && cp "$model.asc" "$dest"/
    test -r "$proj/keys" && cp -r "$proj/keys" "$dest"/ 2>/dev/null
    echo "DROPPED AVALON.md + keys/ (a recipient gets the law with the capability)"
  else
    echo "NOTE: no AVALON.md to ship - the friend gets tools without the model"
  fi
  ( cd "$dest" && sha256sum ./* > MANIFEST.sha256 2>/dev/null && sha256sum -c --quiet MANIFEST.sha256 ) \
    && echo "$(date +%Y-%m-%dT%H:%M:%S%z) DROP -> $dest $*" >> "$proj/stage/receipts.log" \
    || { echo "FAIL: landing manifest did not verify" ; rc=1 ; }
fi
exit $rc
