#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: rcourtman
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/rcourtman/Pulse

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"

color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  diffutils \
  policykit-1
msg_ok "Installed Dependencies"

msg_info "Creating User"
if useradd -r -m -d /opt/pulse-home -s /bin/bash pulse; then
  msg_ok "Created User"
else
  msg_error "User creation failed"
  exit 1
fi

msg_info "Installing Pulse"
RELEASE_INFO=$(curl -s https://api.github.com/repos/rcourtman/Pulse/releases/latest)
LATEST_VERSION=$(echo "$RELEASE_INFO" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

mkdir -p /opt/pulse
cd /opt/pulse

temp_file=$(mktemp)
curl -fsSL "https://github.com/rcourtman/Pulse/releases/download/${LATEST_VERSION}/pulse-${LATEST_VERSION}.tar.gz" -o "$temp_file"
tar -xzf "$temp_file"
rm -f "$temp_file"

echo "${LATEST_VERSION#v}" >/opt/${APPLICATION}_version.txt

bash install.sh
msg_ok "Installed Pulse"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"