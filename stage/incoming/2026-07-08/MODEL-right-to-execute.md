# MODEL-right-to-execute — consent-based execution proposals on the wire

> Stage-5 pivot synthesis, Alpha-C4-Wire2 campaign, 2026-07-08. Pub-safe:
> method only. Builds on c4-0.0.1-ALPHAv0.1.2.md §2 (the four signing
> layers); designed to the gap the field names open (verifiable delegation
> across the tool/agent seam) and the garden already half-owns.

## The object: an Execution Proposal (EP)

An EP is a signed claim that **specific bytes, from a specific pinned
public source, by a specific committer, may run in a specific scope** —
and it is *only a proposal* until the receiving user counter-signs.

What an EP carries (all inside the signed span — Alfred's fold; a
normalizer that touches any of it is tamper by sha):

1. **Content pin** — sha256 of the hunk bytes; optionally the bytes
   themselves, else fetch instructions: public repo URL + commit hash +
   path. Pinned commit in a public repo means the *stream of code content*
   is auditable by anyone, forever — no private substitution.
2. **Committer pin** — key fingerprint of who committed the content
   (identity layer; the wire's pinned-key discipline, which A2A v1.0's
   Signed Agent Cards independently arrived at).
3. **Scope declaration** — what assembly grants: registers the hunk may
   write (register-only value discipline), taxonomy letters it touches,
   run-level ceiling (0–5), and its **dominance level** (Universal /
   Domain / Community / Home) — meaning always localizable at root.
4. **Proposer signature** — the peer (or the keeper's own agent) signing
   the *proposal*, distinct from the committer signing the *content*.
   Provenance weight comes from keeper-backing; the verification floor
   still comes from the artifact class (code → content review + gates).
5. **Semaphores** — NO4C-family transit controls ride with the payload:
   RAISED parks assembly, MENTIONED notes, CARRIED disarms only by
   explicit rename. The payload carries its own brakes.

## The grant: user counter-signature (the consent event)

- **Nothing assembles on proposal alone.** The user's counter-signature
  over the EP hash is the grant; it lands in the **register** (quartet:
  identity·package·subscription·register — WHO, WHAT, GRANT, PROOF).
- Silence ≠ consent; no timer lifts a park; revoke = delete the roster
  line (one line per identity, per CSH).
- **For-me / to-me line:** verification, ledgering, refusal, receipts are
  done *for* the user; scope grants, roster edits, counter-signing stay
  *to* the user. Any migration across that line is a consent regression
  by definition — this is the model's falsifier surface.

## The assembler: dumb on purpose

- **Dumb assembler, smart verifier** (Alfred's fold): the assembler only
  places verified hunks; the verifier holds the anchor-to-hash ledger and
  all judgement. Sign-LAST generalizes to assembly: the assembled product
  is signed after composition, over everything, license meta included.
- Refuses unsigned hunks by default; verifies at **assembly time** (the
  act, not a marker — closing C4.md §6's gap with ccspt/CSH verify calls).
- Fail-closed everywhere: unverifiable pin, unknown key, absent register
  entry, raised semaphore — each is a PARK with a receipt, never a warn.

## Why this beats the alternatives it competes with

- vs **"trusted publisher" stores:** the pin is to *content at a commit*,
  not to a publisher's ongoing goodwill; a rug-pull changes the hash and
  the EP simply stops verifying. Nothing to revoke centrally — there is
  no center.
- vs **curl|sh and lockfiles:** lockfiles pin content but carry no consent
  record and no committer accountability; an EP is the lockfile line plus
  WHO stands behind it plus proof the user said yes, in one signed object.
- vs **capability-based "smart" agents deciding:** ALPHA's law — input is
  never authority; generation is not standing. The EP moves nothing on
  cleverness; only accountability acquired (signatures, pins, the grant)
  confers the right to execute.

## Honest limits

- The user counter-sign is a real interaction cost; batching (a signing
  sitting over N proposals) is the usability answer, and it must never
  become auto-grant. The keeper-cap cadence applies.
- Public-repo pinning assumes a public repo: private/embargoed hunks need
  the manifest-vouch pattern (sha-pin + signed manifest) instead.
- An agent cannot durably hold the counter-signing key — the grant is the
  KEEPER's act, always. Operator visibility of any agent-held material is
  the feature.
- Scale problems (roster rotation, revocation discipline >3–4 users)
  inherit from phase0, unsolved here.

## feeds →

BUILD-CONTRAST (stage 6) · QA-2 quartet refinement (license axis + this
model's register semantics) · Avalon lift.sh (the EP park/note semantics
are NO4C's grown-up form) · the wire (EP as a message type, post-trip)
