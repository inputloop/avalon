-----BEGIN PGP SIGNED MESSAGE-----
Hash: SHA512

# Avalon as an assembly line — the keeper's ruling, recorded (2026-07-13)

Both open Avalon questions answered by one idea, so I am writing it down as the
shape rather than as two verdicts.

## The ruling (Corwin, 2026-07-13, in his words and mine)

- - **lift + drop are a pair, and the pair is the point.** Lift protects US from
  what comes in (provenance). Drop protects THEM from what goes out (selection).
  Approved as a pair. The hard-edged gate stands: **drop refuses anything not
  already promoted**, and the keeper's own workaround for his own blocks is to
  park a folder and ask for help bringing it in — *not* to widen the gate. A
  block you can route around by asking is a good block; a block you route around
  silently is a broken one.
- - **movepack and drop are thorny beasts → they become MINI-PROJECTS inside
  Avalon.** Avalon is an **assembly line**: tools march *down* from projects, or
  get *built* inside, are worked on the bench with their own docs and tests, and
  graduate into `utils/` (or `tools/`) when they've earned it.

## The line (four stations)

    projects/*  ──►  Avalon/work/<tool>/   ──►  utils/ | tools/   ──►  drop
    (or built here)      the bench              the collection      outward
                    src + README + tests        signed, promoted    (with AVALON.md)

**`work/<tool>/` — the bench.** One directory per thorny tool:

    work/movepack/
      movepack.sh        the tool
      README.md          what it is, what it refuses, how to run it
      BRING.list         its data (lists are data, not code)
      t/                 the test kit — disposable targets, one file per behavior
      Makefile           check | install | clean   (plain make; autotools when the
                         pain is real, not before)

Graduation criteria, stated so they can be met rather than argued about:
**tests green** on a disposable target · **README** a stranger can run from ·
**path-lint -s** clean · **signed** · **the keeper has read it**. Then it moves
to `utils/` and the bench dir becomes its history.

## The awk/sed rule (the keeper's caution, kept sharp)

> *"We can do tools that are just awk/sed in a tux — potentially quite testable,
> such scripts! — but we don't want to reinvent them."*

So, the line the bench holds:

- - **Compose the standard tools; don't re-implement them.** If `sed`, `awk`,
  `sort`, `sha256sum`, `tar`, `gpg`, `make` already do it, we glue — we do not
  grow our own. Every re-implementation is a new surface with no upstream, no
  users, and no one else's bugs found for us.
- - **Reach for a real language when the shell starts lying.** The tells: nested
  quoting you have to think about twice; parsing anything with structure;
  arithmetic; anything where a wrong answer is silent. (This session produced a
  live specimen: awk has no capture backreferences, so a "clever" `gsub` emitted
  a literal `\1` — the shell was cheerfully wrong. Python, stdlib only, is the
  house's next rung.)
- - **The exception the keeper named:** we *may* internalize a standard operation
  when C4 judges it must be ours — because a signed assembler cannot depend on a
  tool it cannot pin. That is a deliberate, argued exception, written down when
  taken, never a default.

## Why a bench (not just "put it in utils/")

A tool that lands straight in the collection arrives with no tests, no README,
and no way to say what it refuses — and then it is *signed*, which makes it look
finished. The bench is where a tool is allowed to be unfinished in public, and
the graduation is where the promise gets made. Same discipline as the rest of
the shop: **a written step is not a proven step**, and a promoted tool is a
promise to whoever runs it next.

## Proposed first residents

`work/movepack/` (pack/unpack for the move — already behavior-tested on a
disposable target, 6/6) and `work/drop/` (the outward courier — gates drafted,
ruling now in hand). `av` + its completion are small enough to go straight to
`bin/`+`utils/` when you're ready; they invent no behavior, they only route.

Nothing was moved. This was the shape, of Corwin's markup — the tools stayed in
`stage/incoming/` until [[Corwin]] said the line was right.

sentinel: AVALON-ASSEMBLY-LINE-2026-07-13

-----BEGIN PGP SIGNATURE-----

iQGzBAEBCgAdFiEE7Od89BfHbBrPznwrW2E1URWA8AcFAmpUjT4ACgkQW2E1URWA
8AfY6QwA2O+kvaZOu1jQ9gzeN9v+duqf8Zexsn7HatrCg8Fp91BR4pN0nAgrSKAr
dOqYN9gVhuryNGP1w8zTO0SlnXhW1sh/Lm/6ZKsmErCo2hZfq047Z3942vX7NX5N
ehSfb1GwgPlKIrUm315ixt1uhfZfEvpFUbPw4pwnM79p61VtbYeGOUITGv7Wba8b
ea9/tCeLzAsKYwTxzG77SmcqVTxr935zUgRdwgwUn9QdVh0lyK/heORCLGuqvWiF
a3euZTlw4O4cLsJQUFzHBdl6SUdNtsjtCzYIViDWBIvGWYaNiXsxpg0Z9WqYyjap
rFcGBqywqSq3v9K33dhGG5kybfxbRFLf1kzOPiU+OZzyEEzkixB3qvQxSN+gGqAk
fI10NQ5Tag0GnsgOv+969imhKS4d6arjLTZ3zPK+/Ott1xTSjVTBwAn9zWK8P5xa
8gIOofdtCGlzkC65F46lWWXT7AskZJlcmOuA1vfZzxJmwbjyOwg7fSstZZlyVziu
JrXXR8QG
=vWKM
-----END PGP SIGNATURE-----
