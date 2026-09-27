#!/bin/bash
set -e

PKG_NAME="wk2xxx"
PKG_VER="1.0.0"
SRC_DIR="/usr/src/${PKG_NAME}-${PKG_VER}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
KERNELVER="$(uname -r)"

# --- [1/4] Build dependencies ---
echo "=== [1/4] Installing build dependencies ==="
apt update
apt install -y build-essential dkms

# --- [2/4] Kernel headers ---
echo "=== [2/4] Ensuring kernel headers are available ==="

have_headers() {
    ls -d /usr/src/linux-headers-*/ >/dev/null 2>&1
}

if have_headers; then
    echo "[headers] Headers already present:"
    ls -d /usr/src/linux-headers-*/
else
    echo "[headers] No headers in /usr/src, trying to install..."
    # Try exact match first
    if apt-cache show "linux-headers-${KERNELVER}" >/dev/null 2>&1; then
        echo "[headers] Installing linux-headers-${KERNELVER}"
        apt install -y "linux-headers-${KERNELVER}"
    else
        echo "[headers] Exact package linux-headers-${KERNELVER} not available."
        # Try the common Armbian package name
        for pkg in linux-headers-current-rockchip64 linux-headers-current-rockchip linux-headers-generic; do
            if apt-cache show "${pkg}" >/dev/null 2>&1; then
                echo "[headers] Installing ${pkg}"
                apt install -y "${pkg}" || true
                break
            fi
        done
    fi

    if ! have_headers; then
        echo "[headers] ERROR: could not install any kernel headers."
        echo "[headers] Please install headers manually for ${KERNELVER}."
        exit 1
    fi
fi

# --- [3/4] Register and build DKMS module ---
echo "=== [3/4] Registering DKMS module ==="
"${SCRIPT_DIR}/prepare-headers.sh" "${KERNELVER}"

rm -rf "${SRC_DIR}"
mkdir -p "${SRC_DIR}"
cp "${REPO_DIR}/Makefile" "${REPO_DIR}/dkms.conf" "${REPO_DIR}/wk2xxx.c" "${SRC_DIR}/"
cp -r "${SCRIPT_DIR}" "${SRC_DIR}/scripts"
chmod +x "${SRC_DIR}/scripts/"*.sh

dkms remove -m "${PKG_NAME}" -v "${PKG_VER}" --all 2>/dev/null || true
dkms add -m "${PKG_NAME}" -v "${PKG_VER}"
dkms build -m "${PKG_NAME}" -v "${PKG_VER}"
dkms install -m "${PKG_NAME}" -v "${PKG_VER}" --force

# --- [4/4] Enable autoload ---
echo "=== [4/4] Enabling module autoload ==="
echo "${PKG_NAME}" > "/etc/modules-load.d/${PKG_NAME}.conf"

echo
echo "Done. Reboot to load the module."
