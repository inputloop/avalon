# NO4C semantics — raise vs mention (DRAFT-00, 2026-07-08 keeper call: "raise")

Keeper decision 2026-07-08: the lift gate parks on a RAISED NO4C, not a
mention. (pmo #104; the live exemplar: lift parked on SEMAPHORES.md merely
*describing* the marker.) Both spellings bind: NO4C and N04C.

## Definitions

RAISED — the marker is operative, addressed to this gate:
  - line-anchored: the first token on a line (a leading comment leader `#`
    allowed), e.g. `NO4C`, `#NO4C]]`, `N04C ...`;
  - or the closer of an ACTIVE C4 work-order envelope (one that governs the
    operation now being attempted).

MENTIONED — the marker appears mid-prose: quoted, discussed, documented
(SEMAPHORES.md describing the semaphore; a README explaining the gate; this
file). Mention does not park; the lift proceeds and NOTES it in the receipt,
so the occurrence is still on tape.

CARRIED — a retained copy of a past work-order's envelope inside a shipped
tool (archive-markdown.sh:11 today). Disarm by renaming the token in the
carried copy to `NO4C-CARRIED` — by construction it stops matching the raise
pattern but still matches the mention pattern, so it is noted, never parked.
Until renamed, a line-anchored carried marker parks (fail-closed).

## Proposed lift.sh patch (bin/lift.sh:27-28)

    if grep -Eq '^[[:space:]]*#?N[O0]4C([[:space:]]|\]|$)' "$f" && test -z "$force" ; then
      echo "PARK $b: NO4C raised - keeper lowers with -f" ; rc=1 ; continue
    elif grep -Eq 'N[O0]4C' "$f" ; then
      echo "NOTE $b: NO4C mentioned (not raised) - lifting"
    fi

Also: drop "(semantics provisional)" from the header comment (line 8) and the
PARK message — semantics are now decided. PROVENANCE.md row for
archive-markdown.sh updates when its carried marker is renamed.

Fail-closed properties kept: unknown/edge forms that are line-anchored still
park; -f remains the only lower; the receipt records both PARK and NOTE.

Keeper to-dos on accept: apply patch (lift.sh is an executable — detach
sign); rename the carried marker in archive-markdown.sh (or leave it parked
deliberately); re-run `make check`.

sentinel: NO4C-SEMANTICS-DRAFT-00
