-----BEGIN PGP SIGNED MESSAGE-----
Hash: SHA512

# Stage notes — 2026-07-12 drop (instrument-authored, keeper reviews)

Five artifacts, none signed, none promoted. Per Avalon law the keeper reviews
`stage/incoming/` before anything reaches `tools/` or `utils/` — I did not
route around that, and the one item that *would* have (a straight-to-tools
drop) is exactly the thing I stopped to ask about. See OPEN QUESTIONS.

## What's here

| file | proposed home | what it is |
|---|---|---|
| `movepack.sh` | `utils/` | pack/unpack a named set of materials for a move. The LIST is the authority; the tool never guesses what to bring. |
| `BRING.list` | `utils/` (or repo root) | the Giza list: deny rules first, then materials. Edit freely — it is meant to be read by a human in a hurry. |
| `av` | `bin/` | one door to the kit: `av lift|drop|pack|unpack|lint|verify|check|where`. |
| `av.bash-completion` | `utils/` | `<TAB>` recites the kit's shape back to you. |
| `drop.sh` | `bin/` — **STOPPED, see below** | outward counterpart to `lift.sh`. |

## Proving the behavior (S16 — a parsed flag is not a behavior)

`movepack.sh` was exercised on a disposable target with a planted secret
(`id_ed25519`) and a planted `SAVANNAH/` path. Six checks, all observed, not
asserted:

1. unknown flag `--bogus` → rejected loudly, exit 2 (never silently ignored)
2. `-n` dry run → resolved 2 files, wrote **nothing**; target byte-identical
   before/after (checked, not assumed)
3. deny gate → both planted paths named, whole pack **refused**, no archive
   written. A deny is a PARK, never a silent skip: a silent skip is how the
   wrong thing travels.
4. happy path → packed 2, unpacked elsewhere, manifest verified
5. tamper → one byte appended inside the archive; unpack **parked**, 0 files
   landed (manifest travels inside the archive and is checked before a byte
   is trusted)
6. missing include → **parked** with the offending line named (absence is a
   reading too)

Receipts appended for every pack and unpack, permanently.

## Ergonomics — why a dispatcher and not just PATH

PATH gives you the verbs; it does not give you the **shape**. `av <TAB>`
recites the kit — and when the shape is wrong you stop, which is the whole
point. Setup is three lines in `~/.bashrc`:

    export AVALON=/f/claude/projects/Avalon
    export PATH="$AVALON/bin:$PATH"
    . "$AVALON/utils/av.bash-completion"

`av where` prints the paths for eyes and for scripts, so a cold session (or a
cold volunteer) can orient without reading the Makefile.

## OPEN QUESTIONS for the keeper

1. **`drop.sh` — the administration question, asked not assumed.** A drop is
   a *lift in reverse*: kit → a friend's stage. Lift's gates protect US from
   what comes in. A drop's gates protect THEM from what goes out — which
   means the interesting gate is not provenance but **selection**: does this
   artifact carry a case, a path, a person? The draft below deliberately
   gates on the same three (sig, path-lint, NO4C) plus a `.gate`/pub-safe
   check, and — the part I want your ruling on — it **refuses to drop
   anything not already promoted to `tools/`**, so a drop can never become a
   side door around the review queue. If you'd rather it stage directly for
   speed, say so and I'll widen it; but that is you lowering a gate, on the
   record, not me routing around one.
2. **`AVALON.md` / public stage.** Yes — Avalon should carry a pub-safe
   `AVALON.md` (the project's own model: what it is, its law, what a
   recipient may assume). That makes "stage out a copy for a friend" a
   one-liner: drop the model + the tools it names. Draft is in
   `AVALON.md.draft` here; it is a *model*, not a README — the README tells
   you how to run the kit, the model tells you what the kit believes.
3. **Where does `movepack` live long-term?** It is Avalon-shaped (POSIX,
   receipts, gates) but it is not a *method* tool lifted from the enclave —
   it is a moving tool. If `utils/` is for conveniences, it belongs there.
   Your call.

sentinel: AVALON-STAGE-NOTES-2026-07-12

-----BEGIN PGP SIGNATURE-----

iQGzBAEBCgAdFiEE7Od89BfHbBrPznwrW2E1URWA8AcFAmpUeDwACgkQW2E1URWA
8Ac4cQv7BCfO+mroXbGYeUUd8TBsVCr/AwM6WTVGGlKY+K8lNgCkPZHm7dggBOlW
+vdW+nSHXRKCYeLitq47qjorthUr++gw1uuV7ix1AkyHpBmC70PyOGQ7L7toTszq
tDoBjN5tjcr8OcUbpDLbEo4pi3Ccs6PyeZDtoTfLCeuetDVSf3NRA/KRZCEXDBOq
l+lRnvmdfL41/2QMr/n+R0urvEteCFl82pulp2LvXH+9jFDcQ95/D+jh8BOgKifJ
oNdFP5nLJnUxEZbUHp41VXSTc+gHIchCqv2KeFnD9lZtP77hglepfoEZp1mm16ZJ
CmBaiSsAGt247E49CHO6LI/N+b7JMfiMFu8ZCP835ovyh9QqGsImB/ScmSYyH12T
MW8345aRhE1x8R48kD2Rl/bxAgRkKBJALSTYOTZE/vf8G3ZbYuYKUss1lUYSPofT
AfynyNH5PcZERn80Qc86Eu1Wn37iQPO7oG+w0X/vSlLosCF/m/Gg/FD/xnuxE8Wp
7HmC/tu+
=6xHz
-----END PGP SIGNATURE-----
