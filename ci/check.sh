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

if [ ! -f meta-edge/conf/layer.conf ] || [ ! -f kas/qemuarm64.yml ]; then
  echo "layer/kas config not created yet — skipping build"; exit 0
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
