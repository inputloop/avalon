#!/usr/bin/bash
# lift - one-way stage lifter: enclave artifact -> Avalon stage/incoming
# Gates, in order (each is a hard PARK unless noted):
#   1. sig      - detached .asc beside the file, verifies Good vs keys/ (2/2)
#                 no sig, no lift
#   2. dialect  - tools/path-lint.sh -s passes (PATH-DIALECT pin:
#                 no lint pass, no MANIFEST)
#   3. NO4C     - warn+PARK; semantics provisional; keeper lowers with -f
#   4. landing  - sha256 manifest verified at destination; receipt appended
# Law: method travels, cases don't. The lifter cannot judge that - the
# keeper reviews stage/incoming/ before anything promotes to tools/.
proj=$(cd "$(dirname "$0")/.." && pwd)
stage=$proj/stage/incoming/$(date +%Y-%m-%d)
lint=$proj/tools/path-lint.sh
force= ; if test "$1" = "-f" ; then force=1 ; shift ; fi
if ! test -n "$1" ; then echo "Usage: $(basename $0) [-f] FILE..." ; exit 2 ; fi
export GNUPGHOME=$(mktemp -d) ; chmod 700 "$GNUPGHOME"
gpg -q --import "$proj"/keys/*.asc 2>/dev/null || { echo "no keys in $proj/keys" ; exit 3 ; }
rc=0
for f in "$@" ; do
  b=$(basename "$f")
  if ! test -r "$f.asc" ; then echo "PARK $b: no detached sig (no sig, no lift)" ; rc=1 ; continue ; fi
  if ! gpg --verify "$f.asc" "$f" 2>&1 | grep -q 'Good signature' ; then
    echo "PARK $b: signature does not verify vs pinned keys" ; rc=1 ; continue ; fi
  if ! "$lint" -s "$f" >/dev/null ; then
    echo "PARK $b: path-lint -s failed (no lint pass, no MANIFEST)" ; rc=1 ; continue ; fi
  if grep -q 'NO4C' "$f" && test -z "$force" ; then
    echo "PARK $b: NO4C raised (semantics provisional) - keeper lowers with -f" ; rc=1 ; continue ; fi
  mkdir -p "$stage"
  cp "$f" "$f.asc" "$stage"/ || { echo "FAIL $b: copy" ; rc=1 ; continue ; }
  ( cd "$stage" && sha256sum "$b" "$b.asc" >> MANIFEST.sha256 && sha256sum -c --quiet MANIFEST.sha256 ) \
    || { echo "FAIL $b: landing did not verify" ; rc=1 ; continue ; }
  echo "$(date +%Y-%m-%dT%H:%M:%S%z) LIFT $f -> $stage/$b $(sha256sum "$f" | cut -d' ' -f1)" >> "$proj/stage/receipts.log"
  echo "LIFTED $b -> $stage"
done
exit $rc
