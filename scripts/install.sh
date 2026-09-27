#!/bin/bash
set -e

PKG_NAME="wk2xxx"
PKG_VER="1.0.0"
SRC_DIR="/usr/src/${PKG_NAME}-${PKG_VER}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
KERNELVER="$(uname -r)"

apt update
apt install -y build-essential dkms

"${REPO_DIR}/scripts/prepare-headers.sh" "${KERNELVER}"

rm -rf "${SRC_DIR}"
mkdir -p "${SRC_DIR}"
cp "${REPO_DIR}/Makefile" "${REPO_DIR}/dkms.conf" "${REPO_DIR}/wk2xxx.c" "${SRC_DIR}/"
cp -r "${REPO_DIR}/scripts" "${SRC_DIR}/scripts"
chmod +x "${SRC_DIR}/scripts/"*.sh

dkms remove -m "${PKG_NAME}" -v "${PKG_VER}" --all 2>/dev/null || true
dkms add -m "${PKG_NAME}" -v "${PKG_VER}"
dkms build -m "${PKG_NAME}" -v "${PKG_VER}"
dkms install -m "${PKG_NAME}" -v "${PKG_VER}" --force

echo "${PKG_NAME}" > "/etc/modules-load.d/${PKG_NAME}.conf"
echo "Done. Reboot."
