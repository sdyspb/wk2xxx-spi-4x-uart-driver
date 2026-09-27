#!/bin/bash
# Prepare kernel headers for DKMS build on custom Armbian kernels.
#
# DKMS requires the directory specified in kernel_source_dir to exist
# before the build starts. This script creates a symlink at that path
# pointing to the best available headers.
#
# Usage: prepare-headers.sh [kernelver]
#   kernelver - defaults to `uname -r`

set -e

KERNELVER="${1:-$(uname -r)}"
BASE="/usr/src/wk2xxx-headers"
DEST="${BASE}/${KERNELVER}"

# Already prepared
if [ -d "${DEST}" ] && [ -e "${DEST}/Makefile" ]; then
    echo "[prepare-headers] Already prepared: ${DEST}"
    exit 0
fi

mkdir -p "${BASE}"

# 1. Native headers for this exact kernel version
NATIVE="/usr/src/linux-headers-${KERNELVER}"
if [ -d "${NATIVE}" ]; then
    ln -sfn "${NATIVE}" "${DEST}"
    echo "[prepare-headers] Linked native headers: ${NATIVE} -> ${DEST}"
    exit 0
fi

# 2. Fallback: any headers available in /usr/src
for d in /usr/src/linux-headers-*/; do
    [ -d "$d" ] || continue
    ln -sfn "${d%/}" "${DEST}"
    echo "[prepare-headers] WARNING: ${KERNELVER} headers not found."
    echo "[prepare-headers] Falling back to: ${d%/}"
    echo "[prepare-headers] Build may fail if kernel API differs."
    exit 0
fi

echo "[prepare-headers] ERROR: no kernel headers found in /usr/src/"
echo "[prepare-headers] Install linux-headers or provide kernel source."
exit 1
