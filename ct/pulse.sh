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
  
  RELEASE_INFO=$(curl -s https://api.github.com/repos/rcourtman/Pulse/releases/latest)
  LATEST_VERSION=$(echo "$RELEASE_INFO" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
  RELEASE="${LATEST_VERSION#v}"
  
  if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
    msg_info "Stopping ${APP}"
    systemctl stop pulse
    msg_ok "Stopped ${APP}"

    msg_info "Updating Pulse to ${LATEST_VERSION}"
    temp_file=$(mktemp)
    
    if [ -d /opt/pulse/data ]; then
      cp -r /opt/pulse/data /tmp/pulse-data-backup
    fi
    
    rm -rf /opt/pulse/*
    curl -fsSL "https://github.com/rcourtman/Pulse/releases/download/${LATEST_VERSION}/pulse-${LATEST_VERSION}.tar.gz" -o "$temp_file"
    tar -xzf "$temp_file" -C /opt/pulse
    
    if [ -d /tmp/pulse-data-backup ]; then
      cp -r /tmp/pulse-data-backup /opt/pulse/data
      rm -rf /tmp/pulse-data-backup
    fi
    
    cd /opt/pulse
    if [ -f install.sh ]; then
      bash install.sh --update
    fi
    
    rm -f "$temp_file"
    echo "${RELEASE}" >/opt/${APP}_version.txt
    msg_ok "Updated Pulse to ${LATEST_VERSION}"

    msg_info "Starting ${APP}"
    systemctl start pulse
    msg_ok "Started ${APP}"
  else
    msg_ok "No update required. ${APP} is already at ${RELEASE}."
  fi
  exit  
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:7655${CL}"
