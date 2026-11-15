#!/usr/bin/env bash
# Local verification: build the image(s) and run image tests. Grows with the project.
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="$HOME/.local/bin:$PATH"
export DL_DIR="$HOME/.cache/yocto/downloads" SSTATE_DIR="$HOME/.cache/yocto/sstate"
mkdir -p "$DL_DIR" "$SSTATE_DIR"

echo "== shellcheck =="
shopt -s nullglob globstar
f=(scripts/**/*.sh ci/*.sh); [ ${#f[@]} -eq 0 ] || shellcheck "${f[@]}"

echo "== kas YAML syntax =="
python3 - <<'PYEOF'
import sys, pathlib
try:
    import yaml
except ImportError:
    print("PyYAML not available — skipping kas YAML check"); sys.exit(0)
errs = []
for p in sorted(pathlib.Path("kas").glob("*.yml")):
    try:
        yaml.safe_load(p.read_text())
    except yaml.YAMLError as e:
        errs.append(f"{p}: {e}")
if errs:
    print("\n".join(errs)); sys.exit(1)
print(f"OK ({len(list(pathlib.Path('kas').glob('*.yml')))} files)")
PYEOF

echo "== meta-edge layer.conf =="
python3 - <<'PYEOF'
import sys, pathlib
p = pathlib.Path("meta-edge/conf/layer.conf")
if not p.exists():
    print("not present — skipping"); sys.exit(0)
c = p.read_text()
for field in ("BBPATH", "BBFILES", "BBFILE_COLLECTIONS", "LAYERSERIES_COMPAT"):
    if field not in c:
        print(f"missing required field: {field}"); sys.exit(1)
if "wrynose" not in c:
    print("LAYERSERIES_COMPAT does not include 'wrynose'"); sys.exit(1)
print("OK")
PYEOF

echo "== edgeos distro conf =="
python3 - <<'PYEOF'
import sys, pathlib
p = pathlib.Path("meta-edge/conf/distro/edgeos.conf")
if not p.exists():
    print("not present — skipping"); sys.exit(0)
c = p.read_text()
for field in ("DISTRO", "DISTRO_NAME", "DISTRO_VERSION", "TARGET_VENDOR",
              "DISTRO_FEATURES", "VIRTUAL-RUNTIME_init_manager"):
    if field not in c:
        print(f"missing required field: {field}"); sys.exit(1)
if "systemd" not in c:
    print("systemd not declared in distro conf"); sys.exit(1)
print("OK")
PYEOF

if [ ! -f meta-edge/conf/layer.conf ] || [ ! -f kas/qemuarm64.yml ] || \
   [ ! -f meta-edge/recipes-core/images/edgeos-image.bb ]; then
  echo "== skipping kas build (layer/image not fully configured yet) =="
  echo "ALL CHECKS PASSED"
  exit 0
fi

KAS_CFG="kas/qemuarm64.yml"
[ -f kas/check.yml ] && KAS_CFG="$KAS_CFG:kas/check.yml"   # extra features enabled for verification

echo "== kas build ($KAS_CFG) =="
kas-container build "$KAS_CFG"

if grep -rqs 'testimage' kas/ meta-edge/conf/ 2>/dev/null; then
  echo "== testimage =="
  kas-container shell "$KAS_CFG" -c "bitbake -c testimage edgeos-image"
fi

if [ -x scripts/extra-checks.sh ]; then scripts/extra-checks.sh; fi
echo "ALL CHECKS PASSED"
