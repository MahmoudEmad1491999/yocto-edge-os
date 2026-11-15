# 0002 — edgeos distro conf and meta-edge layer skeleton

**Date:** 2026-11-15

## Context
Phase 0 bring-up needs a Yocto layer (`meta-edge`) and an OE distro definition
(`edgeos`) before any image can be built. The distro must work without Poky —
only openembedded-core (wrynose) + bitbake (2.18) are pinned by kas.

## Decision
`meta-edge/conf/layer.conf` declares `LAYERSERIES_COMPAT_edge = "wrynose"` and
priority 10 (above oe-core=5 and meta-oe=6), giving our recipes precedence.

`meta-edge/conf/distro/edgeos.conf` is written from scratch, mirroring
nodistro.conf's minimal style. `DISTRO_FEATURES` is set explicitly for a
headless edge device: networking (`ipv4`, `ipv6`), security helpers (`acl`,
`xattr`, `pam`), and `systemd`. `VIRTUAL-RUNTIME_init_manager = "systemd"` and
`DISTRO_FEATURES_BACKFILL_CONSIDERED += "sysvinit pulseaudio"` ensure systemd
is selected without sysvinit being pulled in by the backfill mechanism.

## Alternatives considered
- **require nodistro.conf then override**: avoids duplication but creates a
  dependency on OE-core's internal file layout; fragile if that path changes.
- **Poky distro**: no wrynose branch exists; not available.

## Consequences
- `ci/check.sh` now has lightweight Python validators for both conf files,
  independent of BitBake or kas-container.
- The kas build step still requires `edgeos-image.bb` to exist (next task);
  the CI guard has been updated to reflect this.
