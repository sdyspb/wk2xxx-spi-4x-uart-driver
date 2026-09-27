#!/bin/bash
# Postinst hook for kernel installation.
#
# Called by the kernel package postinst script after a new kernel
# is installed. Must run BEFORE the dkms hook so that the fallback
# headers are prepared before DKMS autoinstall triggers.
#
# Installed by wk2xxx installer to /etc/kernel/postinst.d/.
# The numeric prefix 50 ensures this runs before /etc/kernel/postinst.d/dkms
# (alphabetical order).

set -e

KERNELVER="$1"

if [ -z "${KERNELVER}" ]; then
    exit 0
fi

# Only act if the wk2xxx DKMS module is registered
if ! dkms status -m wk2xxx 2>/dev/null | grep -q .; then
    exit 0
fi

# Prepare fallback headers for the new kernel version
if [ -x /usr/src/wk2xxx-1.0.0/scripts/prepare-headers.sh ]; then
    /usr/src/wk2xxx-1.0.0/scripts/prepare-headers.sh "${KERNELVER}" || true
fi
