# yocto-edge-os — rules for the coding agent

## Goal
A small, production-style embedded Linux distribution for an **industrial edge gateway**, built with
Yocto 6.0 "Wrynose" (LTS) and run in QEMU (`qemuarm64`, later also `qemux86-64`). Features a hiring manager
recognises: custom distro/layer, systemd services, read-only rootfs, A/B OTA (RAUC), secure defaults,
SBOM/CVE reporting, automated image tests.

## Layout
```
kas/base.yml            pinned layers: bitbake (2.18), openembedded-core (wrynose), meta-openembedded (wrynose), meta-edge
kas/qemuarm64.yml       machine include; kas/<feature>.yml for optional features (rauc, dev, ...)
meta-edge/              our layer: conf/distro/edgeos.conf, recipes-core/images/edgeos-image.bb, recipes-*/...
apps/                   source for our own applications (built by recipes via externalsrc or file://)
scripts/                run-qemu.sh, helpers
docs/design/ docs/journal/ (human-only — never edit journal)
```
No `poky` repo (it has no Wrynose branch); we use openembedded-core + our own `edgeos` distro.

## Host constraints — IMPORTANT
- Laptop: 24 threads, **16 GB RAM** (Wrynose recommends 32 GB). Always build through `kas-container`
  (avoids Ubuntu 24.04 AppArmor/userns issues) with `BB_NUMBER_THREADS = "6"`, `PARALLEL_MAKE = "-j 6"`,
  `INHERIT += "rm_work"`. Never add recipes that pull in LLVM/clang or large Rust builds unless a task demands it.
- DL_DIR / SSTATE_DIR live outside the repo (`~/.cache/yocto/{downloads,sstate}`) — check.sh exports them.
- No sudo. QEMU runs with slirp networking (`runqemu ... slirp nographic`).

## Rules
- Every recipe: LICENSE + LIC_FILES_CHKSUM, SRCREV pinned, `oelint-adv` clean (once added).
- Every new image feature gets an image test (`meta-edge/lib/oeqa/runtime/cases/edgeos_*.py`) run via `testimage`.
- Keep `edgeos-image` lean; development tools go in `edgeos-image-dev`.
- Extend `ci/check.sh` as the project grows; it must run every test that exists.

## Commit style
Conventional Commits, scopes: `distro`, `image`, `kernel`, `rauc`, `app`, `security`, `test`, `kas`, `docs`.
