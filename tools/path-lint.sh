#!/usr/bin/bash
# path-lint - catch wrong-dialect paths before an artifact stages or signs
# default: poison scan (/sessions/ VM scratch; AppData session scratch)
# -s: ceremony-strict - additionally flag Windows drive paths (pin: /f/ only)
# exit 0 clean, 1 findings, 2 usage; law lives in PATH-DIALECT.md (the pin)
strict=
if test "$1" = "-s" ; then strict=1 ; shift ; fi
if ! test -n "$1" ; then echo "Usage: $(basename $0) [-s] FILE..." ; exit 2 ; fi
rc=0
for f in "$@" ; do
  if ! test -r "$f" ; then echo "SKIP (unreadable) $f" ; rc=1 ; continue ; fi
  p=$(grep -nE '/sessions/[A-Za-z0-9._-]+/mnt|AppData.Roaming.Claude' "$f")
  if test -n "$p" ; then echo "POISON $f:" ; echo "$p" ; rc=1 ; fi
  if test -n "$strict" ; then
    w=$(grep -nE '[A-Za-z]:\\' "$f")
    if test -n "$w" ; then echo "DIALECT $f (pin says /f/):" ; echo "$w" ; rc=1 ; fi
  fi
done
exit $rc
