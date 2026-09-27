#!/bin/bash
# WK2xxx DKMS driver installer for Armbian (RK3568 and compatible).
set -e

PKG_NAME="wk2xxx"
PKG_VER="1.0.0"
SRC_DIR="/usr/src/${PKG_NAME}-${PKG_VER}"
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
KERNELVER="$(uname -r)"

echo "=== [1/7] Installing build dependencies ==="
apt update
apt install -y build-essential dkms device-tree-compiler

# Try to install headers; may fail on custom builds — that is expected.
if apt-cache show "linux-headers-${KERNELVER}" >/dev/null 2>&1; then
    apt install -y "linux-headers-${KERNELVER}"
else
    echo "[install] WARNING: linux-headers-${KERNELVER} not available."
    echo "[install] Falling back to any installed headers."
fi

echo "=== [2/7] Preparing kernel headers ==="
# Create /usr/src/wk2xxx-headers/${KERNELVER} (symlink to best available headers)
"${REPO_DIR}/scripts/prepare-headers.sh" "${KERNELVER}"

echo "=== [3/7] Installing sources to ${SRC_DIR} ==="
rm -rf "${SRC_DIR}"
mkdir -p "${SRC_DIR}"
cp "${REPO_DIR}/Makefile" \
   "${REPO_DIR}/dkms.conf" \
   "${REPO_DIR}/wk2xxx.c" \
   "${SRC_DIR}/"
cp -r "${REPO_DIR}/scripts" "${SRC_DIR}/scripts"
chmod +x "${SRC_DIR}/scripts/"*.sh

echo "=== [4/7] Registering DKMS module ==="
dkms remove -m "${PKG_NAME}" -v "${PKG_VER}" --all 2>/dev/null || true
dkms add -m "${PKG_NAME}" -v "${PKG_VER}"
dkms build -m "${PKG_NAME}" -v "${PKG_VER}"
dkms install -m "${PKG_NAME}" -v "${PKG_VER}" --force

echo "=== [5/7] Installing Device Tree overlay ==="
if [ -f "${REPO_DIR}/overlays/pixelnas-wk2xxx.dts" ]; then
    cp "${REPO_DIR}/overlays/pixelnas-wk2xxx.dts" /boot/overlay-user/
    armbian-add-overlay /boot/overlay-user/pixelnas-wk2xxx.dts
fi

echo "=== [6/7] Enabling module autoload ==="
echo "${PKG_NAME}" > "/etc/modules-load.d/${PKG_NAME}.conf"

echo "=== [7/7] Installing postinst hook for kernel updates ==="
install -m 0755 "${REPO_DIR}/scripts/50-wk2xxx-headers.sh" /etc/kernel/postinst.d/

echo
echo "=== DONE ==="
echo "Reboot required to apply Device Tree overlay."
echo "After reboot, check: ls /dev/ttyWK*"
