# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2024-present Nicholas Ricciuti (https://github.com/rishooty)

PKG_NAME="i3status"
PKG_VERSION="2.14"
PKG_SHA256="5c4d0273410f9fa3301fd32065deda32e9617fcae8b3cb34793061bf21644924"
PKG_LICENSE="BSD"
PKG_SITE="https://i3wm.org/i3status/"
PKG_URL="https://i3wm.org/i3status/i3status-${PKG_VERSION}.tar.xz"
PKG_DEPENDS_TARGET="toolchain libconfuse yajl libnl alsa-lib pulseaudio"
PKG_LONGDESC="i3status is a small program for generating a status bar for i3bar, dzen2, xmobar or similar programs."
PKG_TOOLCHAIN="meson"

PKG_MESON_OPTS_TARGET="-Dpulseaudio=true"

post_makeinstall_target() {
  mkdir -p ${INSTALL}/etc
  cp ${PKG_DIR}/config/i3status.conf ${INSTALL}/etc/
}