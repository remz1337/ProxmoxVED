#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVED/raw/main/LICENSE
# Source: https://github.com/rustmailer/bichon

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os
setup_hwaccel

fetch_and_deploy_gh_release "bichon" "rustmailer/bichon" "prebuild" "latest" "/opt/bichon" "bichon-*-x86_64-unknown-linux-gnu.tar.gz"
mkdir -p /opt/bichon-data

msg_info "Setting up Bichon"
cat <<EOF >/opt/bichon/bichon.env
BICHON_ROOT_DIR=/opt/bichon-data
BICHON_LOG_LEVEL=info
EOF
msg_ok "Setup Bichon"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/bichon.service
[Unit]
Description=Bichon service
After=network.target

[Service]
Type=simple
User=root
EnvironmentFile=/opt/bichon/bichon.env
WorkingDirectory=/opt/bichon
ExecStart=/opt/bichon/bichon
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now bichon
msg_info "Created Service"

motd_ssh
customize
cleanup_lxc
