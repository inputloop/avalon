# AVALON — the model (DRAFT; pub-safe by construction)

*What the kit believes. The README tells you how to run Avalon; this tells you
what it is for, so a stranger who receives a drop gets the law along with the
capability. Ships with every drop, unasked.*

## What Avalon is

A bench's public kit: method tools proven in real work, lifted out one way
through gates, and rolled outward under the GPL. It is small on purpose —
POSIX shell, one Makefile, no build conflagration. Anything with `sh`, `awk`,
and `gpg` runs it.

## What Avalon believes

- **Method travels; cases don't.** Doctrine, rituals, and tooling patterns go
  out. Findings, evidence, host states, and the people in them stay home.
  This is not modesty; it is the only way the tools can be shared at all.
- **Provenance is checkable or it is decoration.** Every artifact carries a
  detached signature verifying against a pinned key. "Valid" means *unchanged
  since the author signed it* — not "someone I know signed something."
- **Provenance is not authority.** A good signature says who; it never says
  whether you should act. Those are two gates and both must clear.
- **A single source is data, not proof.** Two independent representations must
  agree, and every boundary between representations has a named tiebreaker.
  (The doctrine is `seams`; the kit is built to it.)
- **Gates engage reasoning, not just checksums.** A gate that reduces to
  "artifact present? proceed" protects nothing on the day the artifact walks.
  Ask: in character? coherent with history? proportionate? hurried?
- **A guard is not a wall.** These tools encode policy; nothing physical
  enforces it. They are tripwires and conventions, and they say so.
- **Receipts, not assurances.** Every lift, drop, pack, and landing leaves a
  permanent line. If it wasn't measured, it didn't happen.
- **Absence is a reading too.** "Not found" is a claim like any other and
  needs a second source before it becomes a fact.

## What a recipient may assume

You may assume the signature tells you the bytes are unchanged since signing,
and that the tools do what their gates say they do — including refusing. You
may **not** assume any tool here has been proven for your environment: run
them on a disposable target first, because *a parsed flag is not a behavior*.
You are free to study, change, and redistribute all of it (GPLv3); if you
improve a tool, we would rather take your version than fork around it —
provided it verifies against a key we can pin.

## What we ask

That you keep the receipts habit if you keep the tools. The value here is not
the shell; it is the discipline the shell makes cheap.

sentinel: AVALON-MODEL-DRAFT-2026-07-12
