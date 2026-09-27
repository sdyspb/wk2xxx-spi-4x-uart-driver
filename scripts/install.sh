#!/bin/bash
# WK2xxx DKMS driver installer for Armbian (RK3568)
set -e

PKG_NAME="wk2xxx"
PKG_VER="1.0.0"
SRC_DIR="/usr/src/${PKG_NAME}-${PKG_VER}"
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "=== [1/6] Installing build dependencies ==="
apt update
apt install -y build-essential dkms linux-headers-$(uname -r) device-tree-compiler

echo "=== [2/6] Installing sources to ${SRC_DIR} ==="
mkdir -p "${SRC_DIR}"
cp "${REPO_DIR}/Makefile" "${REPO_DIR}/dkms.conf" "${REPO_DIR}/wk2xxx.c" "${SRC_DIR}/"

echo "=== [3/6] Registering DKMS module ==="
dkms add -m "${PKG_NAME}" -v "${PKG_VER}" || true
dkms build -m "${PKG_NAME}" -v "${PKG_VER}"
dkms install -m "${PKG_NAME}" -v "${PKG_VER}" --force

echo "=== [4/6] Installing Device Tree overlay ==="
if [ -f "${REPO_DIR}/overlays/pixelnas-wk2xxx.dts" ]; then
    cp "${REPO_DIR}/overlays/pixelnas-wk2xxx.dts" /boot/overlay-user/
    armbian-add-overlay /boot/overlay-user/pixelnas-wk2xxx.dts
fi

echo "=== [5/6] Enabling module autoload ==="
echo "${PKG_NAME}" > /etc/modules-load.d/${PKG_NAME}.conf

echo "=== [6/6] Done ==="
echo "Reboot required to apply Device Tree overlay."
echo "After reboot, check: ls /dev/ttyWK*"
