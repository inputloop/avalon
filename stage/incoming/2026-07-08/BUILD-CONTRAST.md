# BUILD-CONTRAST — two build-step models for the patched ALPHA line, contrasted

> Stage-6 design, Alpha-C4-Wire2 campaign, 2026-07-08. Corwin's preferred
> shape: model both, contrast them. Pub-safe.

## Model A — the local patched build ("works for us")

The drop stays pristine in the outbox; the working line lives beside the
models. Build step, POSIX-plain:

    inputs:   outbox drop (verified: sigs GOOD, manifest OK)
              models/c4/patches/*.patch (the offered P1–P5)
    step:     copy drop → models/c4/local/ALPHAv0.1.2+p1.md
              apply semantic patches (hand-fold; they are prose diffs)
              record: sha256 of result + patch list → local/RECEIPT
    output:   the local line, clearly marked LOCAL — never represents
              upstream; upstream master is Bryant's, mint-never-edit
    sign:     keeper detach-signs result + RECEIPT (one sitting)

- **Cheap** (one sitting), **honest** (drop untouched, local marked),
  **fragile at scale** (hand-folded patches don't re-apply mechanically
  when v0.1.3 arrives; the fold is a human act each time).

## Model B — the ccspt bake (the productized path)

The same step expressed as ccspt pipeline stages, so the build itself
carries provenance:

    init:     workspace with pinned inputs (drop sha256s from the signed
              MANIFEST; patch shas from the signed patch file)
    ingest:   drop + patches as consent-stated inputs (in-toto statements:
              WHO provided WHAT under WHICH consent)
    verify:   2/2 — signatures against pinned keys AND shas against the
              in-toto record; fail-closed
    publish:  emit ALPHAv0.1.2+p1.md + a build attestation (inputs,
              steps, outputs, all hashed) — the attestation IS the receipt
    sign:     keeper signs the attestation; the artifact inherits

- **Repeatable** (v0.1.3 re-bakes by editing one input pin), **auditable
  by strangers** (the attestation answers "how was this built" without
  trusting us), **heavier** (ccspt wiring now, for a two-garden audience).

## The contrast (where they diverge is the information)

| Axis | A local | B ccspt |
|---|---|---|
| Cost now | one sitting | tooling session |
| Re-apply on v0.1.3 | manual re-fold | re-pin + re-run |
| Stranger-auditable | receipt (trust us) | attestation (verify us) |
| Consent record | keeper sig on result | in-toto per input |
| Matches EP model | partially (pins, no scope) | fully (EP = its wire form) |
| Failure mode | silent patch drift | pipeline bit-rot |

**Read:** A is the right build *today* (two gardens, pre-shutdown, one
sitting); B is the right build *the moment a third party consumes the
line* — because B's attestation is exactly the Execution Proposal of
MODEL-right-to-execute in build-time clothes. The pivot model and the
build model converge on the same object from two directions, which is the
strongest internal evidence this pass produced: **the EP is not an extra
invention; it is what both the wire AND the build step independently
want.**

**Decision offered (keeper's):** run Model A now (stage-8 box), leave
Model B as the standing design with a pmo todo gated on "third consumer
appears" — the same trigger the federation-expansion gate already uses.

## Losers kept

- "Patch upstream directly" — dies on mint-never-edit; upstream is
  Bryant's. Parked, revive never.
- "Vendor the whole drop into the repo" — dies on externs-memory-only
  rule (externs feed candidates via memory/, not trees). Parked; revive
  only if the drop becomes a build input for shipped code.
