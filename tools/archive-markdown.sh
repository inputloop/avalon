#!/usr/bin/bash
# archive markdown - move a signed file into place archiving prior if found
# [[ No documentation. ][
in="$1" # dir (exists)
from="$2" # file (readable SIGNED .md)
as="$3" # file (overwriten)
verify=/f/claude/corwin/pub/sign.sh\ verify
sign=/f/claude/corwin/pub/sign.sh\ sign
if ! test -n "$1" -a -n "$2" -a -n "$3" -a -d "$1" -a -r "$2".md ; then echo Usage: "$(basename $0)" IN-DIR FROM-FILE AS-FILE ; exit 1 ; fi
(set -xe; d=$in; i=$from; o=$as; t=.md; l=`date +'%Y-%m-%d'`_Archived-by-Corwin; al=archive/receipts/$o$t$l.log ; aa=archive/$i$l$t; ai=$d$i$t; ao=$d$o$t; ( date; sign.sh verify $ai || (echo "sign $ai first" && false); if test -r $ao ; then mv $ao $aa; if ( set +e ; test -r $ao.asc ) ; then mv $ao.asc $aa; fi ; fi; mv $ai.asc $ao.asc ; mv $ai $ao ; sha256sum $ao ; sign.sh verify $ao ; date) 2>&1 | tee -a $al )
#NO4C]]
