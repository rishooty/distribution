# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2018-present Frank Hartung (supervisedthinking @ gmail.com)
# Copyright (C) 2023 JELOS (https://github.com/JustEnoughLinuxOS)

PKG_NAME="qt6"
PKG_VERSION="8a875b0dcb6b7b9405f0a39d481a73cbcde19b8a"
PKG_LICENSE="GPL"
PKG_SITE="http://qt-project.org"
PKG_URL="https://invent.kde.org/qt/qt/qt5.git"
PKG_DEPENDS_HOST="ninja:host"
PKG_DEPENDS_TARGET="toolchain ${PKG_DEPENDS_HOST} openssl libjpeg-turbo libpng pcre2 sqlite zlib freetype SDL2 libxkbcommon gstreamer gst-plugins-base gst-plugins-good gst-libav"
PKG_LONGDESC="A cross-platform application and UI framework"
PKG_TOOLCHAIN="cmake"
GET_HANDLER_SUPPORT="git"
PKG_GIT_CLONE_BRANCH="6.2.4"
PKG_GIT_CLONE_SINGLE="yes"

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
  if [ "${VULKAN_SUPPORT}" = "yes" ]; then
    PKG_DEPENDS_TARGET+=" vulkan-loader vulkan-headers"
  fi
}

pre_configure_target() {
PKG_CMAKE_OPTS_TARGET="-GNinja \
                       -DQT_ALLOW_SYMLINK_IN_PATHS=ON \
                       -DCMAKE_INSTALL_PREFIX=/usr \
                       -DINSTALL_BINDIR=/usr/bin \
                       -DINSTALL_LIBDIR=/usr/lib \
                       -DINSTALL_INCLUDEDIR=/usr/include \
                       -DINSTALL_ARCHDATADIR=/usr/lib \
                       -DINSTALL_DOCDIR=/usr/share/doc/qt6 \
                       -DINSTALL_DATADIR=/usr/share \
                       -DFEATURE_optimize_size=ON \
                       -DBUILD_SHARED_LIBS=ON \
                       -DFEATURE_sql=OFF \
                       -DFEATURE_system_sqlite=OFF \
                       -DINPUT_openssl=linked \
                       -DFEATURE_system_zlib=ON \
                       -DFEATURE_system_pcre2=ON \
                       -DFEATURE_system_harfbuzz=ON \
                       -DFEATURE_icu=OFF \
                       -DFEATURE_glib=OFF \
                       -DFEATURE_cups=OFF \
                       -DFEATURE_fontconfig=ON \
                       -DFEATURE_egl=ON \
                       -DFEATURE_gbm=ON \
                       -DFEATURE_kms=ON \
                       -DQT_BUILD_TESTS=OFF \
                       -DQT_BUILD_EXAMPLES=OFF \
                       -DQT_HOST_PATH=/usr/lib/x86_64-linux-gnu/qt6 \
                       -DQt6HostInfo_DIR=/usr/lib/x86_64-linux-gnu/cmake/Qt6HostInfo \
                       -DQt6CoreTools_DIR=/usr/lib/x86_64-linux-gnu/cmake/Qt6CoreTools \
                       -DQt6_DIR=/usr/lib/x86_64-linux-gnu/cmake/Qt6 \
                       -DCMAKE_PREFIX_PATH=/usr/lib/x86_64-linux-gnu/cmake \
                       -DQT_FORCE_BUILD_TOOLS=ON \
                       -DCMAKE_TOOLCHAIN_FILE=${CMAKE_CONF}"

  # OpenGL options
  if [ "${OPENGLES_SUPPORT}" = "yes" ]; then
    PKG_CMAKE_OPTS_TARGET+=" -DINPUT_opengl=es2"
  else
    PKG_CMAKE_OPTS_TARGET+=" -DINPUT_opengl=desktop"
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
    PKG_CMAKE_OPTS_TARGET+=" -DFEATURE_vulkan=OFF -DNO_VULKAN=ON -DINPUT_vulkan=no -DFEATURE_vkgen=OFF -DFEATURE_vkkhrdisplay=OFF"
  fi

  # Create CMake toolchain file
  cat > ${CMAKE_CONF} << EOF
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR ${TARGET_ARCH})
set(CMAKE_C_COMPILER ${CC})
set(CMAKE_CXX_COMPILER ${CXX})
set(CMAKE_SYSROOT ${SYSROOT_PREFIX})
set(CMAKE_FIND_ROOT_PATH ${SYSROOT_PREFIX})
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
EOF
}

post_makeinstall_target() {
  # Remove references to the build directory from installed library dependencies
  find ${SYSROOT_PREFIX}/usr/lib/ -name \*.prl -exec sed -i -e '/^QMAKE_PRL_BUILD_DIR/d' {} \;

  # Create directories
  mkdir -p ${INSTALL}/usr/lib
  mkdir -p ${INSTALL}/usr/plugins
  mkdir -p ${INSTALL}/usr/qml

  # Install Qt6 libs
  for PKG_QT6_LIBS in \
    libQt6Concurrent libQt6Core libQt6DBus libQt6Gui libQt6Network libQt6OpenGL \
    libQt6Qml libQt6QmlModels libQt6Quick libQt6QuickControls2 libQt6QuickTemplates2 \
    libQt6Sql libQt6Svg libQt6Test libQt6Widgets libQt6Xml
  do
    cp -PR ${SYSROOT_PREFIX}/usr/lib/${PKG_QT6_LIBS}.so* ${INSTALL}/usr/lib
  done

  # Install Qt6 plugins
  for PKG_QT6_PLUGINS in \
    imageformats platforms sqldrivers
  do
    cp -PR ${SYSROOT_PREFIX}/usr/plugins/${PKG_QT6_PLUGINS} ${INSTALL}/usr/plugins
  done

  # Install Qt6 QML
  for PKG_QT6_QML in \
    Qt QtQml QtQuick QtQuick3D QtTest
  do
    cp -PR ${SYSROOT_PREFIX}/usr/qml/${PKG_QT6_QML} ${INSTALL}/usr/qml
  done

  # Install libs, plugins & qml for Wayland/X11 display server
  if [ ${DISPLAYSERVER} = "x11" ]; then
    cp -PR ${SYSROOT_PREFIX}/usr/lib/libQt6XcbQpa.so*      ${INSTALL}/usr/lib
    cp -PR ${SYSROOT_PREFIX}/usr/plugins/xcbglintegrations ${INSTALL}/usr/plugins
  elif [ ${DISPLAYSERVER} = "wl" ]; then
    cp -PR ${SYSROOT_PREFIX}/usr/lib/libQt6WaylandClient.so*     ${INSTALL}/usr/lib
    cp -PR ${SYSROOT_PREFIX}/usr/lib/libQt6WaylandCompositor.so* ${INSTALL}/usr/lib

    cp -PR ${SYSROOT_PREFIX}/usr/plugins/platforms/libqwayland*              ${INSTALL}/usr/plugins/platforms
    cp -PR ${SYSROOT_PREFIX}/usr/plugins/wayland-decoration-client           ${INSTALL}/usr/plugins
    cp -PR ${SYSROOT_PREFIX}/usr/plugins/wayland-graphics-integration-client ${INSTALL}/usr/plugins
    cp -PR ${SYSROOT_PREFIX}/usr/plugins/wayland-graphics-integration-server ${INSTALL}/usr/plugins
    cp -PR ${SYSROOT_PREFIX}/usr/plugins/wayland-shell-integration           ${INSTALL}/usr/plugins

    cp -PR ${SYSROOT_PREFIX}/usr/qml/QtWayland ${INSTALL}/usr/qml
  fi

  # Install EGLFS libs & plugins if OpenGLES is supported
  if [ "${OPENGLES_SUPPORT}" = "yes" ]; then
    if [ ${DISPLAYSERVER} = "no" ]; then
      cp -PR ${SYSROOT_PREFIX}/usr/lib/libQt6EglFSDeviceIntegration.so* ${INSTALL}/usr/lib
      cp -PR ${SYSROOT_PREFIX}/usr/plugins/egldeviceintegrations        ${INSTALL}/usr/plugins
    fi
  fi
}
