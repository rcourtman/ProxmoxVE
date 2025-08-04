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

msg_info "Creating dedicated user pulse..."
if useradd -r -m -d /opt/pulse-home -s /bin/bash pulse; then
  msg_ok "User created."
else
  msg_error "User creation failed."
  exit 1
fi

# Get latest release info
msg_info "Checking for latest Pulse release"
RELEASE_INFO=$(curl -s https://api.github.com/repos/rcourtman/Pulse/releases/latest)
LATEST_VERSION=$(echo "$RELEASE_INFO" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

if [ -z "$LATEST_VERSION" ]; then
  msg_error "Failed to get latest release info"
  exit 1
fi

msg_ok "Latest version: $LATEST_VERSION"

# Install Pulse v4 (Go version)
msg_info "Installing Pulse"
mkdir -p /opt/pulse
cd /opt/pulse

# Download universal package
temp_file=$(mktemp)
curl -fsSL "https://github.com/rcourtman/Pulse/releases/download/${LATEST_VERSION}/pulse-${LATEST_VERSION}.tar.gz" -o "$temp_file"
tar -xzf "$temp_file"
rm -f "$temp_file"

# Set version file for update script compatibility
echo "${LATEST_VERSION#v}" >/opt/${APPLICATION}_version.txt

# Run the installer
if [ -f install.sh ]; then
  bash install.sh
else
  msg_error "Installer not found in package"
  exit 1
fi

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"