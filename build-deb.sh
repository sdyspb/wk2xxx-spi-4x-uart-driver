#!/bin/bash
set -e

PKG_NAME="wk2xxx-dkms"
PKG_VER="1.0.0"
ARCH="all"
OUT="${PKG_NAME}_${PKG_VER}_${ARCH}.deb"
ROOT="$(cd "$(dirname "$0")" && pwd)"
BUILD="$(mktemp -d)"
trap 'rm -rf "${BUILD}"' EXIT

cp -r "${ROOT}/deb/." "${BUILD}/"

mkdir -p "${BUILD}/usr/src/wk2xxx-${PKG_VER}/scripts"
cp "${ROOT}/Makefile" "${ROOT}/dkms.conf" "${ROOT}/wk2xxx.c" \
   "${BUILD}/usr/src/wk2xxx-${PKG_VER}/"
cp "${ROOT}/scripts/prepare-headers.sh" "${ROOT}/scripts/post-build.sh" \
   "${BUILD}/usr/src/wk2xxx-${PKG_VER}/scripts/"
chmod +x "${BUILD}/usr/src/wk2xxx-${PKG_VER}/scripts/"*.sh
chmod 755 "${BUILD}/DEBIAN/postinst" \
          "${BUILD}/DEBIAN/prerm" \
          "${BUILD}/DEBIAN/postrm"

dpkg-deb --root-owner-group --build "${BUILD}" "${ROOT}/${OUT}"
echo "Built: ${ROOT}/${OUT}"
