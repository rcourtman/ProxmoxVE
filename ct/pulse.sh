#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: rcourtman
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/rcourtman/Pulse

APP="Pulse"
var_tags="${var_tags:-monitoring,proxmox}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-4}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ -d /opt/pulse-monitor ]]; then
  msg_error "An old installation was detected. Please recreate the LXC from scratch (https://github.com/community-scripts/ProxmoxVE/pull/4848)"
  exit 1
  fi
  if [[ ! -d /opt/pulse ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  
  msg_info "Stopping ${APP}"
  systemctl stop pulse
  msg_ok "Stopped ${APP}"
  
  ARCH=$(dpkg --print-architecture)
  case $ARCH in
    amd64) PULSE_ARCH="amd64" ;;
    arm64) PULSE_ARCH="arm64" ;;
    armhf) PULSE_ARCH="armv7" ;;
    *) msg_error "Unsupported architecture: $ARCH"; exit 1 ;;
  esac
  
  fetch_and_deploy_gh_release "pulse" "rcourtman/Pulse" "prebuild" "latest" "/opt/pulse" "pulse-*-linux-${PULSE_ARCH}.tar.gz"
  
  msg_info "Starting ${APP}"
  systemctl start pulse
  msg_ok "Started ${APP}"
  
  msg_ok "Updated Successfully"
  exit  
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:7655${CL}"
