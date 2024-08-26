PKG_NAME="libconfuse"
PKG_VERSION="3.3"
PKG_SHA256="1dd50a0320e135a55025b23fcdbb3f0a81913b6d0b0a9df8cc2fdf3b3dc67010"
PKG_LICENSE="ISC"
PKG_SITE="https://github.com/libconfuse/libconfuse"
PKG_URL="https://github.com/libconfuse/libconfuse/releases/download/v${PKG_VERSION}/confuse-${PKG_VERSION}.tar.xz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="libConfuse is a configuration file parser library written in C"
PKG_TOOLCHAIN="autotools"

PKG_CONFIGURE_OPTS_TARGET="--enable-shared \
                           --disable-static \
                           --disable-examples"

post_makeinstall_target() {
  rm -rf ${INSTALL}/usr/bin
}
