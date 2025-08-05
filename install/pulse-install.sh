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
mkdir -p /opt/pulse
ARCH=$(dpkg --print-architecture)
case $ARCH in
  amd64) PULSE_ARCH="amd64" ;;
  arm64) PULSE_ARCH="arm64" ;;
  armhf) PULSE_ARCH="armv7" ;;
  *) msg_error "Unsupported architecture: $ARCH"; exit 1 ;;
esac

fetch_and_deploy_gh_release "pulse" "rcourtman/Pulse" "prebuild" "latest" "/opt/pulse" "pulse-*-linux-${PULSE_ARCH}.tar.gz"

mkdir -p /etc/pulse
echo "${LATEST_VERSION#v}" >/opt/${APPLICATION}_version.txt
chown -R pulse:pulse /etc/pulse /opt/pulse
msg_ok "Installed Pulse"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/pulse.service
[Unit]
Description=Pulse Monitoring Server
After=network.target

[Service]
Type=simple
User=pulse
Group=pulse
WorkingDirectory=/opt/pulse
ExecStart=/opt/pulse/pulse
Restart=always
RestartSec=3
StandardOutput=journal
StandardError=journal
Environment="PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
Environment="PULSE_DATA_DIR=/etc/pulse"

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now pulse
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"