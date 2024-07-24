# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2022-present JELOS (https://github.com/JustEnoughLinuxOS)

PKG_NAME="parallel-n64-lr"
PKG_VERSION="3c35d867592e553bf80b8984f98e9eae3b6c4ed9"
PKG_LICENSE="GPLv2"
PKG_SITE="https://gitlab.com/parallel-launcher/parallel-n64"
PKG_URL="${PKG_SITE}.git"
PKG_DEPENDS_TARGET="toolchain core-info"
PKG_LONGDESC="A fork of ParallelN64 that adds the GLideN64 graphics plugin and some additional settings and features. Designed to be used with Parallel Launcher."
PKG_TOOLCHAIN="make"
PKG_BUILD_FLAGS="-lto"

if [ ! "${OPENGL}" = "no" ]; then
  PKG_DEPENDS_TARGET+=" ${OPENGL} glu libglvnd"
fi

if [ "${OPENGLES_SUPPORT}" = yes ]; then
  PKG_DEPENDS_TARGET+=" ${OPENGLES}"
fi

if [ "${VULKAN_SUPPORT}" = "yes" ]; then
  PKG_MAKE_OPTS_TARGET+=" HAVE_PARALLEL=1 HAVE_PARALLEL_RSP=1"
fi

PKG_MAKE_OPTS_TARGET+=" platform=${DEVICE} WITH_DYNAREC=${ARCH}"

pre_configure_target() {
  if [ "${ARCH}" = "aarch64" ]; then
    # This is only needed for armv8.2-a targets where we don't use this flag
    # as it prohibits the use of LSE-instructions, this is a package bug most likely
    export CFLAGS="${CFLAGS} -mno-outline-atomics"
    export CXXFLAGS="${CXXFLAGS} -mno-outline-atomics"
  fi
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  cp parallel_n64_libretro.so ${INSTALL}/usr/lib/libretro/

  mkdir -p ${INSTALL}/usr/config/retroarch
  cp -rf ${PKG_DIR}/config/* ${INSTALL}/usr/config/retroarch/
}

