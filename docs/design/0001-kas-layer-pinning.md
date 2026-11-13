# 0001 — kas layer pinning without Poky

**Date:** 2026-11-14

## Context
Yocto 6.0 "Wrynose" has no Poky branch. We need a reproducible way to fetch
openembedded-core, bitbake, and meta-openembedded at known revisions without
the Poky meta-distribution.

## Decision
Use `kas` (config format v14, requires kas ≥ 4.5) to pin all layers via
branch names (`wrynose`, `2.18`). `kas-container` isolates the build from
Ubuntu 24.04 AppArmor/userns restrictions. Build parallelism is capped at 6
threads / 6 make jobs and `rm_work` is inherited to stay within 16 GB RAM.

## Alternatives considered
- **repo tool**: more flexible but requires a manifest repo and manual
  local.conf management — kas does both in one file.
- **Poky**: no wrynose branch exists upstream; using it would require a fork.
- **Pinning to full SRCREVs**: preferred for production releases but requires
  network access at config time; branch names are sufficient for development
  and are promoted to SRCREVs on release.

## Consequences
- `kas-container` must be installed on the developer machine (Docker ≥ 24).
- `DL_DIR`/`SSTATE_DIR` are exported by `ci/check.sh` and mounted by
  `kas-container`; they are not hardcoded in local.conf.
- When `meta-edge/conf/layer.conf` does not yet exist, `check.sh` skips
  the full build and only validates YAML syntax and shell scripts.
