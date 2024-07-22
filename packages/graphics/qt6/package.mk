# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2018-present Frank Hartung (supervisedthinking @ gmail.com)
# Copyright (C) 2023 JELOS (https://github.com/JustEnoughLinuxOS)

PKG_NAME="qt6"
PKG_VERSION="6.7.2"
PKG_LICENSE="GPL"
PKG_SITE="http://qt-project.org"
PKG_URL="https://download.qt.io/official_releases/qt/6.7/${PKG_VERSION}/single/qt-everywhere-src-${PKG_VERSION}.tar.xz"
PKG_DEPENDS_HOST="ninja:host"
PKG_DEPENDS_TARGET="toolchain ${PKG_DEPENDS_HOST} openssl libjpeg-turbo libpng pcre2 sqlite zlib freetype SDL2 libxkbcommon gstreamer gst-plugins-base gst-plugins-good gst-libav"
PKG_LONGDESC="A cross-platform application and UI framework"

configure_host() {
  mkdir -p ${PKG_BUILD}/.host
  cd ${PKG_BUILD}/.host

  cmake -GNinja \
        -DCMAKE_INSTALL_PREFIX=${PKG_BUILD}/.host \
        -DCMAKE_BUILD_TYPE=Release \
        -DFEATURE_optimize_full=ON \
        -DFEATURE_shared=OFF \
        -DFEATURE_static=ON \
        -DBUILD_SHARED_LIBS=OFF \
        -DFEATURE_sql=OFF \
        -DFEATURE_openssl=OFF \
        -DFEATURE_sql_sqlite=OFF \
        -DFEATURE_system_zlib=OFF \
        -DFEATURE_system_pcre2=OFF \
        -DFEATURE_icu=OFF \
        -DFEATURE_glib=OFF \
        -DFEATURE_cups=OFF \
        -DFEATURE_fontconfig=OFF \
        -DFEATURE_vulkan=OFF \
        -DFEATURE_opengl=OFF \
        -DFEATURE_egl=OFF \
        -DFEATURE_gbm=OFF \
        -DFEATURE_kms=OFF \
        -DBUILD_qtbase=ON \
        -DBUILD_qtdeclarative=OFF \
        -DBUILD_qttools=ON \
        -DBUILD_qttranslations=OFF \
        -DBUILD_qtdoc=OFF \
        -DBUILD_EXAMPLES=OFF \
        -DBUILD_TESTS=OFF \
        ..
}

make_host() {
  cd ${PKG_BUILD}/.host
  ninja
}

makeinstall_host() {
  cd ${PKG_BUILD}/.host
  ninja install
}

configure_package() {
  # Apply project specific patches
  PKG_PATCH_DIRS="${PROJECT}"

  # Build with OpenGL / OpenGLES support
  if [ "${OPENGL_SUPPORT}" = "yes" ]; then
    PKG_DEPENDS_TARGET+=" ${OPENGL}"
  elif [ "${OPENGLES_SUPPORT}" = "yes" ]; then
    PKG_DEPENDS_TARGET+=" ${OPENGLES}"
  fi

  # Build with XCB support for X11
  if [ ${DISPLAYSERVER} = "x11" ]; then
    PKG_DEPENDS_TARGET+=" xcb-util xcb-util-image xcb-util-keysyms xcb-util-renderutil xcb-util-wm"
  fi

  # Wayland support
  if [ "${DISPLAYSERVER}" = "wl" ]; then
    PKG_DEPENDS_TARGET+=" wayland xcb-util xcb-util-image xcb-util-keysyms xcb-util-renderutil xcb-util-wm"
  fi

  # Vulkan support
  if [ "${VULKAN_SUPPORT}" = "yes" ]
  then
    PKG_DEPENDS_TARGET+=" vulkan-loader vulkan-headers"
  fi
}

pre_configure_target() {
  export PATH="${PKG_BUILD}/.host/bin:${PATH}"

  PKG_CMAKE_OPTS_TARGET="-GNinja \
                         -DCMAKE_INSTALL_PREFIX=/usr \
                         -DINSTALL_BINDIR=/usr/bin \
                         -DINSTALL_LIBDIR=/usr/lib \
                         -DINSTALL_INCLUDEDIR=/usr/include \
                         -DINSTALL_ARCHDATADIR=/usr/lib \
                         -DINSTALL_DOCDIR=/usr/share/doc/qt6 \
                         -DINSTALL_DATADIR=/usr/share \
                         -DFEATURE_optimize_full=ON \
                         -DFEATURE_shared=ON \
                         -DFEATURE_static=OFF \
                         -DFEATURE_sql_sqlite=ON \
                         -DFEATURE_openssl_linked=ON \
                         -DFEATURE_system_sqlite=ON \
                         -DFEATURE_system_zlib=ON \
                         -DFEATURE_system_pcre2=ON \
                         -DFEATURE_system_harfbuzz=OFF \
                         -DFEATURE_icu=OFF \
                         -DFEATURE_glib=OFF \
                         -DFEATURE_cups=OFF \
                         -DFEATURE_fontconfig=ON \
                         -DFEATURE_egl=ON \
                         -DFEATURE_gbm=ON \
                         -DFEATURE_kms=ON \
                         -DFEATURE_webengine=OFF \
                         -DFEATURE_pdf=OFF \
                         -DFEATURE_qttools=OFF \
                         -DFEATURE_quick3d=OFF \
                         -DFEATURE_quicktimeline=OFF \
                         -DFEATURE_virtualkeyboard=OFF \
                         -DFEATURE_qtwebengine=OFF \
                         -DFEATURE_qtpdf=OFF \
                         -DBUILD_TESTING=OFF \
                         -DBUILD_EXAMPLES=OFF"

  # OpenGL options
  if [ "${OPENGLES_SUPPORT}" = "yes" ]; then
    PKG_CMAKE_OPTS_TARGET+=" -DFEATURE_opengl_es2=ON"
  else
    PKG_CMAKE_OPTS_TARGET+=" -DFEATURE_opengl=ON"
  fi

  # Wayland support
  if [ "${DISPLAYSERVER}" = "wl" ]; then
    PKG_CMAKE_OPTS_TARGET+=" -DFEATURE_wayland=ON"
  else
    PKG_CMAKE_OPTS_TARGET+=" -DFEATURE_wayland=OFF"
  fi

  # Vulkan support
  if [ "${VULKAN_SUPPORT}" = "yes" ]; then
    PKG_CMAKE_OPTS_TARGET+=" -DFEATURE_vulkan=ON"
  else
    PKG_CMAKE_OPTS_TARGET+=" -DFEATURE_vulkan=OFF"
  fi
}

configure_target() {
  mkdir -p ${PKG_BUILD}/.${TARGET_NAME}
  cd ${PKG_BUILD}/.${TARGET_NAME}
  
  cmake ${PKG_CMAKE_OPTS_TARGET} \
        -DQT_HOST_PATH=${PKG_BUILD}/.host \
        ..
}

makeinstall_target() {
  ninja install DESTDIR=${INSTALL}
}

post_makeinstall_target() {
  # Remove references to the build directory from installed library dependencies
  find ${INSTALL}/usr/lib/ -name \*.prl -exec sed -i -e '/^QMAKE_PRL_BUILD_DIR/d' {} \;

  # Create directories
  mkdir -p ${INSTALL}/usr/lib
  mkdir -p ${INSTALL}/usr/plugins
  mkdir -p ${INSTALL}/usr/qml

  # Sysroot path to Qt6 files
  PKG_QT6_SYSROOT_PATH=${PKG_ORIG_SYSROOT_PREFIX:-${SYSROOT_PREFIX}}/usr

  # Install Qt6 libs
  for PKG_QT6_LIBS in \
    libQt6Concurrent libQt6Core libQt6DBus libQt6Gui libQt6Network libQt6OpenGL \
    libQt6Qml libQt6QmlModels libQt6Quick libQt6QuickControls2 libQt6QuickTemplates2 \
    libQt6Sql libQt6Svg libQt6Test libQt6Widgets libQt6Xml
  do
    cp -PR ${PKG_QT6_SYSROOT_PATH}/lib/${PKG_QT6_LIBS}.so* ${INSTALL}/usr/lib
  done

  # Install Qt6 plugins
  for PKG_QT6_PLUGINS in \
    imageformats platforms sqldrivers
  do
    cp -PR ${PKG_QT6_SYSROOT_PATH}/plugins/${PKG_QT6_PLUGINS} ${INSTALL}/usr/plugins
  done

  # Install Qt6 QML
  for PKG_QT6_QML in \
    Qt QtQml QtQuick QtQuick3D QtTest
  do
    cp -PR ${PKG_QT6_SYSROOT_PATH}/qml/${PKG_QT6_QML} ${INSTALL}/usr/qml
  done

  # Install libs, plugins & qml for Wayland/X11 display server
  if [ ${DISPLAYSERVER} = "x11" ]; then
    cp -PR ${PKG_QT6_SYSROOT_PATH}/lib/libQt6XcbQpa.so*      ${INSTALL}/usr/lib
    cp -PR ${PKG_QT6_SYSROOT_PATH}/plugins/xcbglintegrations ${INSTALL}/usr/plugins
  elif [ ${DISPLAYSERVER} = "wl" ]; then
    cp -PR ${PKG_QT6_SYSROOT_PATH}/lib/libQt6WaylandClient.so*     ${INSTALL}/usr/lib
    cp -PR ${PKG_QT6_SYSROOT_PATH}/lib/libQt6WaylandCompositor.so* ${INSTALL}/usr/lib

    cp -PR ${PKG_QT6_SYSROOT_PATH}/plugins/platforms/libqwayland*              ${INSTALL}/usr/plugins/platforms
    cp -PR ${PKG_QT6_SYSROOT_PATH}/plugins/wayland-decoration-client           ${INSTALL}/usr/plugins
    cp -PR ${PKG_QT6_SYSROOT_PATH}/plugins/wayland-graphics-integration-client ${INSTALL}/usr/plugins
    cp -PR ${PKG_QT6_SYSROOT_PATH}/plugins/wayland-graphics-integration-server ${INSTALL}/usr/plugins
    cp -PR ${PKG_QT6_SYSROOT_PATH}/plugins/wayland-shell-integration           ${INSTALL}/usr/plugins

    cp -PR ${PKG_QT6_SYSROOT_PATH}/qml/QtWayland ${INSTALL}/usr/qml
  fi

  # Install EGLFS libs & plugins if OpenGLES is supported
  if [ "${OPENGLES_SUPPORT}" = "yes" ]; then
    if [ ${DISPLAYSERVER} = "no" ]; then
      cp -PR ${PKG_QT6_SYSROOT_PATH}/lib/libQt6EglFSDeviceIntegration.so* ${INSTALL}/usr/lib
      cp -PR ${PKG_QT6_SYSROOT_PATH}/plugins/egldeviceintegrations        ${INSTALL}/usr/plugins
    fi
  fi
}
