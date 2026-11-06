#!/usr/bin/bash
# movepack - pack/unpack a named set of materials for a move (the plane, Giza,
# a friend's stage). One list, one archive, one receipt.
# Law: the LIST is the authority; the tool never guesses what to bring.
#   pack   - resolve list -> deny-scan -> tar -> sha256 MANIFEST -> receipt
#   unpack - verify MANIFEST -> extract under a named root -> receipt
# Gates (hard PARK, in order):
#   1. list    - every include resolves, or say which did not (absence is a read)
#   2. deny    - a path matching a deny rule parks the whole pack (not skipped:
#                a silent skip is how the wrong thing travels)
#   3. manifest- sha256 of every member, written INTO the archive; unpack
#                verifies before it trusts a byte
#   4. receipt - every pack and unpack appends to receipts.log, permanently
# Unknown flags are rejected loudly: a parsed flag is not a behavior (S16).
set -u
me=$(basename "$0")
proj=$(cd "$(dirname "$0")" && pwd)
list=$proj/BRING.list
root=.
out=
mode=
dry=

usage () {
  echo "Usage: $me pack   [-n] [-l LIST] [-r ROOT] -o ARCHIVE.tar.gz"
  echo "       $me unpack [-n] [-r ROOT] ARCHIVE.tar.gz"
  echo "  -n dry run (resolve and report; write nothing)"
  echo "  -l LIST  bring-list (default: BRING.list beside this script)"
  echo "  -r ROOT  base dir paths are relative to (default: .)"
  exit "${1:-2}"
}

case "${1:-}" in
  pack|unpack) mode=$1 ; shift ;;
  -h|--help)   usage 0 ;;
  *)           echo "$me: first argument must be 'pack' or 'unpack'" ; usage 2 ;;
esac

while test $# -gt 0 ; do
  case $1 in
    -n) dry=1 ; shift ;;
    -l) test $# -ge 2 || usage 2 ; list=$2 ; shift 2 ;;
    -r) test $# -ge 2 || usage 2 ; root=$2 ; shift 2 ;;
    -o) test $# -ge 2 || usage 2 ; out=$2 ; shift 2 ;;
    --) shift ; break ;;
    -*) echo "$me: unknown option: $1" ; usage 2 ;;   # loud, never ignored
     *) break ;;
  esac
done

test -d "$root" || { echo "$me: no such root: $root" ; exit 3 ; }
rcpt=$proj/receipts.log
stamp=$(date +%Y-%m-%dT%H:%M:%S%z)

# ---- pack ------------------------------------------------------------------
if test "$mode" = pack ; then
  test -n "$out" || { echo "$me: pack needs -o ARCHIVE.tar.gz" ; usage 2 ; }
  test -r "$list" || { echo "$me: cannot read list: $list" ; exit 3 ; }

  # split the list: includes, and deny rules (lines starting '!')
  inc=$(mktemp) ; deny=$(mktemp) ; members=$(mktemp)
  trap 'rm -f "$inc" "$deny" "$members"' EXIT
  sed -e 's/[[:space:]]*#.*$//' -e '/^[[:space:]]*$/d' "$list" > "$inc.raw"
  grep '^!' "$inc.raw" | sed 's/^!//' > "$deny" || true
  grep -v '^!' "$inc.raw" > "$inc" || true

  # 1. list gate - every include must resolve (absence is a reading too)
  miss=0
  while read -r pat ; do
    ( cd "$root" && eval "ls -d $pat" ) >/dev/null 2>&1 || {
      echo "PARK: include does not resolve: $pat" ; miss=1 ; }
  done < "$inc"
  test "$miss" = 0 || { echo "$me: nothing packed (fix the list, or drop the line)" ; exit 1 ; }

  # resolve members (files only; dirs expand)
  while read -r pat ; do
    ( cd "$root" && eval "find $pat -type f -print" ) 2>/dev/null
  done < "$inc" | sort -u > "$members"

  # 2. deny gate - one match parks the whole pack; name every hit
  hits=0
  if test -s "$deny" ; then
    while read -r rule ; do
      while read -r m ; do
        case $m in
          $rule) echo "PARK: '$m' matches deny rule '$rule'" ; hits=$((hits+1)) ;;
        esac
      done < "$members"
    done < "$deny"
  fi
  test "$hits" = 0 || { echo "$me: $hits denied path(s) - pack refused" ; exit 1 ; }

  n=$(wc -l < "$members")
  echo "$me: $n file(s) resolve clean under $root"
  test -z "$dry" || { sed 's/^/  bring  /' "$members" ; echo "$me: dry run - nothing written" ; exit 0 ; }

  # 3. manifest travels INSIDE the archive
  ( cd "$root" && xargs -a "$members" sha256sum ) > "$root/MOVEPACK.sha256" \
    || { echo "$me: manifest failed" ; exit 4 ; }
  ( cd "$root" && tar czf - MOVEPACK.sha256 -T "$members" ) > "$out" \
    || { echo "$me: tar failed" ; exit 4 ; }
  rm -f "$root/MOVEPACK.sha256"
  sum=$(sha256sum "$out" | cut -d' ' -f1)

  # 4. receipt
  echo "$stamp PACK   $out sha256=$sum files=$n list=$list root=$root" >> "$rcpt"
  echo "$me: packed $n file(s) -> $out"
  echo "$me: sha256 $sum   (receipt in $rcpt)"
  echo "$me: verify on arrival with: $me unpack -r DEST $out"
  exit 0
fi

# ---- unpack ----------------------------------------------------------------
test $# -ge 1 || { echo "$me: unpack needs ARCHIVE.tar.gz" ; usage 2 ; }
arc=$1
test -r "$arc" || { echo "$me: cannot read archive: $arc" ; exit 3 ; }
sum=$(sha256sum "$arc" | cut -d' ' -f1)

tmp=$(mktemp -d) ; trap 'rm -rf "$tmp"' EXIT
tar xzf "$arc" -C "$tmp" || { echo "$me: extract failed" ; exit 4 ; }
test -r "$tmp/MOVEPACK.sha256" || { echo "PARK: archive carries no manifest" ; exit 1 ; }

# 3. manifest gate - verify the extracted bytes BEFORE anything lands
( cd "$tmp" && sha256sum -c --quiet MOVEPACK.sha256 ) \
  || { echo "PARK: manifest does not verify - archive is not trustworthy" ; exit 1 ; }
n=$(grep -c . "$tmp/MOVEPACK.sha256")
echo "$me: manifest verifies - $n file(s) intact"
test -z "$dry" || { echo "$me: dry run - nothing landed" ; exit 0 ; }

mkdir -p "$root"
( cd "$tmp" && tar cf - . ) | ( cd "$root" && tar xf - ) \
  || { echo "$me: landing failed" ; exit 4 ; }
rm -f "$root/MOVEPACK.sha256"
echo "$stamp UNPACK $arc sha256=$sum files=$n root=$root" >> "$rcpt"
echo "$me: landed $n file(s) under $root   (receipt in $rcpt)"
