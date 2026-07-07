#!/usr/bin/bash
# mailmove - "move" mail: land a message file in a project Inbox, then
# notify every subscriber by appending an mbox-format notice to the
# spool-file of their choice.
#
# Subscriber list: PROJECT-DIR/Inbox/.subscribers - one per line:
#   name<TAB>/path/to/their/chosen/spool
# Lines blank or starting # are ignored. Spools are mbox: point rmail /
# gnus / mutt at them. No subscribers file = quiet delivery, no notices.
proj="$1" ; msg="$2" ; subj="${3:-$(basename "${2:-}")}"
if ! test -n "$proj" -a -d "$proj" -a -r "$msg" ; then
  echo "Usage: $(basename $0) PROJECT-DIR MSG-FILE [SUBJECT]" ; exit 2 ; fi
inbox=$proj/Inbox ; subs=$inbox/.subscribers
mkdir -p "$inbox"
dest=$inbox/$(date +%Y-%m-%d)-$(basename "$msg")
mv "$msg" "$dest" || exit 1
sha=$(sha256sum "$dest" | cut -d' ' -f1)
echo "delivered: $dest"
if ! test -r "$subs" ; then echo "(no subscribers file: $subs)" ; exit 0 ; fi
while IFS="$(printf '\t')" read -r name spool ; do
  case "$name" in ''|\#*) continue ;; esac
  test -n "$spool" || { echo "SKIP $name: no spool path" ; continue ; }
  mkdir -p "$(dirname "$spool")"
  { echo "From mailmove $(LC_ALL=C date)"
    echo "From: mailmove <mailmove@avalon>"
    echo "To: $name"
    echo "Subject: [$(basename "$proj")] $subj"
    echo "Date: $(date -R)"
    echo "X-SHA256: $sha"
    echo ""
    echo "New drop: $dest"
    echo "sha256:   $sha"
    echo ""
  } >> "$spool" && echo "notified $name -> $spool"
done < "$subs"
