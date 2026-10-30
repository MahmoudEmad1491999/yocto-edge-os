# Roadmap

One task ≈ one day. The agent takes the first unchecked item. First full build takes hours — later tasks reuse sstate.

## Phase 0 — Bring-up
- [ ] `kas/base.yml` (bitbake 2.18, openembedded-core wrynose, meta-openembedded wrynose: meta-oe/meta-python/meta-networking), `kas/qemuarm64.yml`, local.conf limits from CLAUDE.md, `.gitignore`
- [ ] `meta-edge` layer skeleton (layer.conf with LAYERSERIES_COMPAT wrynose) + `edgeos` distro conf derived from nodistro defaults
- [ ] `edgeos-image.bb` (core-image based, minimal); first successful build of the image
- [ ] `scripts/run-qemu.sh`: runqemu nographic slirp with ssh port forward; document login
- [ ] Enable `testimage` with slirp in kas/check.yml; first runtime test `edgeos_boot.py` (os-release has EdgeOS)
- [ ] Distro identity: os-release, issue/motd, hostname, version from git describe
- [ ] systemd as init with a minimal unit set; boot-time measurement (`systemd-analyze`) recorded in docs
- [ ] `edgeos-image-dev` variant with debug-tweaks, gdbserver, strace, ssh with keys

## Phase 1 — Kernel & BSP
- [ ] linux-yocto bbappend in meta-edge with a config fragment (trim unused drivers), note size before/after
- [ ] Custom out-of-tree kernel module recipe (`edge-gpio-sim` character device) + runtime test
- [ ] Device tree / QEMU machine notes; add `qemux86-64` kas machine file and make both machines build
- [ ] Kernel cmdline management and `quiet` boot; measure boot time again
- [ ] Optional PREEMPT_RT kernel via `linux-yocto-rt` behind a kas feature `kas/rt.yml`; runtime test checks `uname -v`

## Phase 2 — Applications
- [ ] `apps/edge-agent` (C or Python): reads simulated sensors from the kernel module, publishes JSON over MQTT
- [ ] Recipe for edge-agent with systemd service, dedicated user, hardening (ProtectSystem, NoNewPrivileges, ...)
- [ ] Mosquitto broker (meta-networking) configured for local-only access; runtime test publishes/subscribes
- [ ] Config via `/etc/edge-agent.toml` with sane defaults; restart-on-change path unit
- [ ] Health endpoint (tiny HTTP) + systemd watchdog integration (`WatchdogSec`, sd_notify)
- [ ] Log management: journald size limits, persistent logs on the data partition
- [ ] Time sync with systemd-timesyncd, fallback NTP config
- [ ] Network config with systemd-networkd (DHCP + static fallback), runtime test for both

## Phase 3 — Storage & read-only rootfs
- [ ] WIC layout: boot + rootfs-A + rootfs-B + data partitions (`edgeos.wks`)
- [ ] Read-only rootfs (`read-only-rootfs` feature) with volatile-binds / overlayfs for /etc changes
- [ ] Data partition auto-mount and growfs on first boot
- [ ] Factory reset mechanism (wipe data partition on flag) + runtime test
- [ ] Runtime test suite: rootfs really read-only, writable paths work, data persists across reboot

## Phase 4 — OTA updates (RAUC)
- [ ] Add meta-rauc (wrynose) via `kas/rauc.yml`; bootloader choice documented (U-Boot for qemuarm64)
- [ ] U-Boot for qemuarm64 with boot script implementing A/B slot selection + boot counting
- [ ] RAUC system.conf, slot definitions, development CA + keys (dev only, clearly marked)
- [ ] Bundle recipe `edgeos-bundle`; `rauc info` verification step in check.sh
- [ ] Update flow test: boot A → install bundle → reboot into B (testimage)
- [ ] Rollback test: install bundle with a deliberately failing health check → automatic fallback to A
- [ ] `rauc-mark-good` service gated on edge-agent health
- [ ] Update server simulation: HTTP server on the host + `edge-update` client polling for new bundles
- [ ] Adaptive / delta updates (casync or block-hash-index) evaluation, document size savings

## Phase 5 — Security
- [ ] Remove debug-tweaks from production image; root login disabled, SSH key-only, admin user with sudo
- [ ] Image hardening checklist (sysctl, mount options nodev/nosuid/noexec, minimal SUID binaries) + runtime tests
- [ ] nftables firewall: default deny inbound except ssh/health; runtime test
- [ ] Signed RAUC bundles with separate dev/release keys and key-rotation notes
- [ ] SBOM: SPDX 3.0 output published as build artifact; doc explaining contents
- [ ] CVE reporting with `sbom-cve-check`; triage file for accepted/ignored CVEs
- [ ] Reproducible builds check for our recipes (build twice, compare package hashes)
- [ ] Secure-boot design doc (U-Boot FIT signature verification) + implement FIT signing in QEMU

## Phase 6 — Developer experience
- [ ] eSDK / standard SDK generation; doc for building edge-agent outside Yocto
- [ ] `devtool` workflow doc with a worked example modifying edge-agent
- [ ] `oelint-adv` config and clean-up of all warnings
- [ ] Shared sstate mirror setup notes; build-time statistics (buildstats) summary
- [ ] Make `kas/` features composable: `kas build kas/qemuarm64.yml:kas/rauc.yml:kas/rt.yml`

## Phase 7 — Integration & polish
- [ ] Container support: podman (meta-virtualization) behind `kas/containers.yml`, run a sample workload
- [ ] Image size budget enforced in check.sh (fail if rootfs grows beyond threshold)
- [ ] Architecture diagram (Mermaid): partitions, update flow, services
- [ ] README: feature list with how each is tested, boot-time and size numbers
- [ ] Release v1.0.0: images, bundle, SBOM and CVE report as release assets; CHANGELOG

## Phase 8 — Extensions
- [ ] Custom `edgeos-initramfs` with early boot health check and recovery shell
- [ ] Recovery mode: boot into initramfs recovery if both slots fail; runtime test
- [ ] TPM-less secret storage design + implementation with encrypted data partition (LUKS, key from file for QEMU)
- [ ] dm-verity on the rootfs (read-only image integrity) + runtime test detects tampering
- [ ] Integrate verity root hash into RAUC bundle / FIT image
- [ ] Device provisioning service: first-boot unique ID, generated SSH host keys, registration call to host simulator
- [ ] Remote management: tiny REST API in edge-agent for status/update trigger, authenticated with a token
- [ ] Prometheus node-exporter-style metrics (or collectd) + scrape from host
- [ ] Log forwarding (systemd-journal-upload) to a host collector
- [ ] OTA campaign simulator on the host: staged rollout to 3 QEMU instances, one fails and rolls back
- [ ] Multi-instance QEMU test harness (3 devices) in scripts/
- [ ] License compliance: archiver class output + license manifest review doc
- [ ] Package feed (opkg/rpm) served from host for incremental package updates (dev image only)
- [ ] Python app recipe with setuptools/pyproject (edge-analytics) + unit tests run in ptest
- [ ] ptest enablement for our recipes, results collected by testimage
- [ ] Boot-time optimisation round 2: systemd unit pruning, kernel initcall_debug analysis, target < 3 s to agent ready
- [ ] Image size optimisation: busybox vs coreutils trade-offs, musl variant experiment (`kas/musl.yml`)
- [ ] Compare glibc vs musl image size & boot time → docs/results
- [ ] Yocto 6.1 forward-compat check note (what breaks, if released by then)
- [ ] Toaster-free build report: buildstats charts (time per recipe) published in docs
- [ ] Integration with rt-kvm-cell: qemux86-64 EdgeOS image runnable as vm-gw (doc + kas file)
- [ ] CycloneDX conversion of SBOM for tooling compatibility (optional)
- [ ] Hardening score: run lynis on target (dev image) and fix top findings
- [ ] Final README polish: feature/test matrix, numbers, how to reproduce from scratch
