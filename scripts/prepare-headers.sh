#!/bin/bash
set -e

KERNELVER="${1:-$(uname -r)}"
BUILD_LINK="/lib/modules/${KERNELVER}/build"
SOURCE_LINK="/lib/modules/${KERNELVER}/source"

# Already prepared
if [ -e "${BUILD_LINK}/Makefile" ]; then
    echo "[prepare-headers] Already prepared: ${BUILD_LINK}"
    exit 0
fi

# 1. Native headers for this exact kernel version
NATIVE="/usr/src/linux-headers-${KERNELVER}"
if [ -d "${NATIVE}" ]; then
    ln -sfn "${NATIVE}" "${BUILD_LINK}"
    ln -sfn "${NATIVE}" "${SOURCE_LINK}"
    echo "[prepare-headers] Linked native headers: ${NATIVE}"
    exit 0
fi

# 2. Fallback: any headers available in /usr/src
for d in /usr/src/linux-headers-*/; do
    [ -d "$d" ] || continue
    ln -sfn "${d%/}" "${BUILD_LINK}"
    ln -sfn "${d%/}" "${SOURCE_LINK}"
    echo "[prepare-headers] WARNING: ${KERNELVER} headers not found."
    echo "[prepare-headers] Falling back to: ${d%/}"
    echo "[prepare-headers] Build may fail if kernel API differs."
    exit 0
done

echo "[prepare-headers] ERROR: no kernel headers found in /usr/src/"
exit 1
