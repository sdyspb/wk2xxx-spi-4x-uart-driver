#!/bin/bash
set -e

KERNELVER="$1"
if [ -z "${KERNELVER}" ]; then
    echo "[post-build] No kernel version argument, skipping"
    exit 0
fi

# Определяем директорию сборки относительно самого скрипта
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
MODULE="${BUILD_DIR}/wk2xxx.ko"

if [ ! -f "${MODULE}" ]; then
    echo "[post-build] ERROR: ${MODULE} not found"
    ls -la "${BUILD_DIR}"
    exit 1
fi

MOD_VM=$(modinfo -F vermagic "${MODULE}" | awk '{print $1}')

if [ "${MOD_VM}" = "${KERNELVER}" ]; then
    echo "[post-build] vermagic OK: ${MOD_VM}"
    exit 0
fi

echo "[post-build] Patching vermagic: ${MOD_VM} -> ${KERNELVER}"

LEN_A=${#MOD_VM}
LEN_B=${#KERNELVER}
if [ "${LEN_A}" -ne "${LEN_B}" ]; then
    echo "[post-build] WARNING: length mismatch (${LEN_A} vs ${LEN_B}), skipping patch"
    exit 0
fi

sed -i "s/${MOD_VM}/${KERNELVER}/" "${MODULE}"
echo "[post-build] New vermagic: $(modinfo -F vermagic "${MODULE}" | awk '{print $1}')"
