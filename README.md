# yocto-edge-os

**EdgeOS**: a custom embedded Linux distribution for an industrial edge gateway, built with
Yocto Project 6.0 "Wrynose" (LTS) and runnable entirely in QEMU.

Highlights (as they land): custom `edgeos` distro on openembedded-core · systemd · read-only rootfs with
overlay for state · A/B over-the-air updates with RAUC and automatic rollback · signed bundles ·
hardened defaults · SBOM + CVE report on every build · automated on-target tests with `testimage`.

> 🚧 Built incrementally — see [ROADMAP.md](ROADMAP.md) and the [development journal](docs/journal).

## Build & run
```sh
pipx install kas
kas-container build kas/qemuarm64.yml
./scripts/run-qemu.sh
```
