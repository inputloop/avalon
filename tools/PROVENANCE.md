# tools/ provenance

Copied VERBATIM from the enclave bench with signatures intact — a signed
artifact is never edited in transit; notes live here, not in the files.

| Tool | Signed | Origin | Notes |
|---|---|---|---|
| path-lint.sh | 2026-07-07, ECE7…F007 | enclave bin/ | dialect lint; law = PATH-DIALECT pin (0.1, signature pending at origin) |
| archive-markdown.sh | 2026-07-07, ECE7…F007 | enclave bin/ | Corwin's install-signed-and-archive-prior tool; carries NO4C marker (semantics provisional) — lifted under keeper override |

Candidates not yet lifted (keeper's triage): savmap.py (signed, but
engagement-adjacent — scrub review first), patternwalk release tgz
(lives on the never-mounts tier; lift from a keeper-made copy only).

sentinel: AVALON-PROVENANCE-01
