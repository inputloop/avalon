-----BEGIN PGP SIGNED MESSAGE-----
Hash: SHA512

# Avalon — the bench's public kit

The workstation model was named AVALON; this project is the bench shipping
its instruments. Method tools proven in the SAVANNAH engagement are lifted
here — one way, through gates — then rolled outward far and wide under the
GPL. Cases never travel; the enclave is not reachable from here or from any
project that consumes this one.

## Law

- - **Selection:** method travels, cases don't. Doctrine, rituals, tooling
  patterns go; findings, evidence, states, runbooks stay home.
- - **Provenance:** every tool carries a detached `.asc` verifying against
  `keys/` (Corwin's published public keys, pinned by fingerprint). "Valid"
  means *unchanged since Corwin signed it*, not "someone signed something."
- - **Lifting:** `bin/lift.sh FILE` — no sig, no lift; no `path-lint -s`
  pass, no MANIFEST; NO4C parks pending keeper override (`-f`); landings
  verify by sha256 with a permanent receipt in `stage/receipts.log`. The
  keeper reviews `stage/incoming/` before anything promotes to `tools/`.
- - **Upstream policy:** if a tool comes to be tended elsewhere, prefer the
  tended version — but only when it verifies against a key we pin. A new
  version that won't verify is not an upgrade; keep or fork ours instead.

## Layout

    bin/       the kit's own machinery (lift.sh)
    tools/     promoted, signed method tools (see PROVENANCE.md)
    utils/     conveniences (mailmove.sh — file-mail with mbox spools)
    keys/      pinned public keys (fingerprint-named)
    stage/     incoming lifts + receipts; keeper's review queue
    Inbox/     project inbox (mailmove target; .subscribers lives here)

## Quickstart

    make            # check = path-lint + signature verify
    make install    # PREFIX=/usr/local by default, DESTDIR honored
    make COPYING    # fetch GPLv3 text (network; run on your own box)
    make dist       # versioned tarball + sha256

## Mail

`utils/mailmove.sh PROJECT-DIR MSG-FILE [SUBJECT]` lands the message in
`PROJECT-DIR/Inbox/` (dated) and appends an mbox-format notice — subject,
date, sha256, path — to each subscriber's chosen spool file, per
`Inbox/.subscribers` (`name<TAB>spool-path`). Local, file-based, no
daemon; point rmail or gnus at your spool.

## License

GPL-3.0-or-later (run `make COPYING` for the text). Copyright the
contributors; free as in freedom.

sentinel: AVALON-KIT-README-01


-----BEGIN PGP SIGNATURE-----

iQGzBAEBCgAdFiEE7Od89BfHbBrPznwrW2E1URWA8AcFAmpNhccACgkQW2E1URWA
8AegFgwAurd2sj05zgsaN5x6qg0JHeX63XdO0DIRYjbggIzDJsMMMR0FiIcSJJw8
1n8ccZom/b9TXNW1pCwR0hLchLjsZfMmIipXGEkfFCWheLstC+X4Wf7bslX7QY57
+hmFZBjrPQNnfWZild0MNCGnDa+n4TFxjoA7N36Wz9UdL89XsCErvqwDGS0gsnaM
Cr6VWbomhz25G3NqL53e6nlBji/4mQRJA+zPpvlnPDicvVEQln/MHPocvL4Gw4qx
0tcc/N8kczB/iBsYWV/BEOKF3AuDMJ/kQ0us2Jx8itAgs066IhmvQ7K4HceXeq3y
aE4F1LqdkdCXwyY992Ld8lSHrD4ujEUz14+biJL6kptaTO1j34Rm6RvGYudXP/C7
IR/EvYPvPLfllaC6PpW3n5+nwIqmBfdHKSFEKiNflqTelLXpR/q6v8zpAech5KY8
zvgYHDgSuJyK5vnAuS9B+xVOdYq/JcF6teIlm6+SGr7J3LjZF+1SXl3EUJIUw+Zn
o81WdK3/
=ZhBx
-----END PGP SIGNATURE-----
