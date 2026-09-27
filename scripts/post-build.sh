#!/bin/bash
# Patch vermagic in the built module if it does not match target kernel.
#
# DKMS calls this after MAKE. If the module was built against headers
# from a different kernel version, the vermagic string will differ,
# and the kernel will refuse to load the module.
#
# Usage: post-build.sh <kernelver>

set -e

KERNELVER="$1"
MODULE="${dkms_tree}/${PACKAGE_NAME}/${PACKAGE_VERSION}/build/wk2xxx.ko"

if [ ! -f "${MODULE}" ]; then
    echo "[post-build] ERROR: ${MODULE} not found"
    exit 1
fi

MOD_VM=$(modinfo -F vermagic "${MODULE}" | awk '{print $1}')

if [ "${MOD_VM}" = "${KERNELVER}" ]; then
    echo "[post-build] vermagic OK: ${MOD_VM}"
    exit 0
fi

echo "[post-build] Patching vermagic: ${MOD_VM} -> ${KERNELVER}"

# Same length check: if lengths differ, sed will corrupt the module.
LEN_A=${#MOD_VM}
LEN_B=${#KERNELVER}

if [ "${LEN_A}" -ne "${LEN_B}" ]; then
    echo "[post-build] WARNING: length mismatch (${LEN_A} vs ${LEN_B})."
    echo "[post-build] Skipping patch. Load with: modprobe --force-vermagic"
    exit 0
fi

sed -i "s/${MOD_VM}/${KERNELVER}/" "${MODULE}"

NEW_VM=$(modinfo -F vermagic "${MODULE}" | awk '{print $1}')
echo "[post-build] New vermagic: ${NEW_VM}"
