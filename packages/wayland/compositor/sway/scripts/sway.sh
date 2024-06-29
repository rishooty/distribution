#!/bin/sh
# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2021-present Team LibreELEC (https://libreelec.tv)

eval $(dbus-launch --sh-syntax)
export LANG=en_US.UTF-8

#Check if waybar exists in .config
if [ ! -d "/storage/.config/waybar" ]; then
    mkdir -p "/storage/.config/waybar"
    cp /etc/xdg/waybar/config.jsonc /storage/.config/waybar/config.jsonc
    cp /etc/xdg/waybar/style.css /storage/.config/waybar/style.css
fi

. /run/sway/sway-daemon.conf
SWAY_LOG_FILE=/var/log/sway.log

if [ ! -z "$(lsmod | grep 'nvidia')" ]; then
  export WLR_NO_HARDWARE_CURSORS=1
  SWAY_GPU_ARGS="--unsupported-gpu"
fi

logger -t Sway "### Starting Sway with -V ${SWAY_GPU_ARGS} ${SWAY_DAEMON_ARGS}"
/usr/bin/sway -V ${SWAY_GPU_ARGS} ${SWAY_DAEMON_ARGS} > ${SWAY_LOG_FILE} 2>&1
