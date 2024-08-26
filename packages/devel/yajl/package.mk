PKG_NAME="yajl"
PKG_VERSION="2.1.0"
PKG_SHA256="3fb73364a5a30efe615046d07e6db9d09fd2b41c763c5f7d3bfb121cd5c5ac5a"
PKG_LICENSE="ISC"
PKG_SITE="https://lloyd.github.io/yajl/"
PKG_URL="https://github.com/lloyd/yajl/archive/refs/tags/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="Yet Another JSON Library - A fast streaming JSON parsing library in C"
PKG_CMAKE_OPTS_TARGET="-DCMAKE_BUILD_TYPE=Release"

configure_package() {
  PKG_CMAKE_OPTS_TARGET+=" -DBUILD_SHARED_LIBS=ON"
}

post_makeinstall_target() {
  rm -rf ${INSTALL}/usr/bin
  rm -rf ${INSTALL}/usr/share
}
