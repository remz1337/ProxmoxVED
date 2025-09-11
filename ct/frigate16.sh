#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/remz1337/ProxmoxVE/remz/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Authors: tteck (tteckster) | Co-Author: remz1337
# License: MIT | https://github.com/remz1337/ProxmoxVE/raw/remz/LICENSE
# Source: https://frigate.video/

APP="Frigate16"
var_tags="${var_tags:-nvr}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-30}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_unprivileged="${var_unprivileged:-0}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -f /etc/systemd/system/frigate.service ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
    
  FRIGATE=$(curl -Ls -o /dev/null -w %{url_effective} https://github.com/blakeblackshear/frigate/releases/latest)
  FRIGATE=${FRIGATE##*/}
  
  GO2RTC=$(curl -s https://api.github.com/repos/AlexxIT/go2rtc/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
  
  FFMPEG="n6.1-latest"
  
  #Once nodejs is installed, can be updated via apt.
  #NODE=$(curl -s https://api.github.com/repos/nodejs/node/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')

  UPD=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "SUPPORT" --radiolist --cancel-button Exit-Script "Spacebar = Select" 11 58 3 \
    "1" "Frigate $FRIGATE" ON \
    "2" "go2rtc $GO2RTC" OFF \
    "3" "ffmpeg $FFMPEG" OFF \
    3>&1 1>&2 2>&3)

  header_info
  #Update Frigate
  if [ "$UPD" == "1" ]; then
    #Ensure enough resources
    if (whiptail --backtitle "Proxmox VE Helper Scripts" --title "Update Frigate" --yesno "Does the LXC have at least 4vCPU  and 4096MiB RAM?" 10 58); then
      CONTINUE=1
    else
      CONTINUE=0
      exit-script
    fi

    echo -e "⚠️  No update path yet for Frigate. Rebuild a new container and copy your configuration"
    exit
  fi
  #Update go2rtc
  if [ "$UPD" == "2" ]; then
    msg_info "Stopping go2rtc"
    systemctl stop go2rtc.service
    msg_ok "Stopped go2rtc"

    msg_info "Updating go2rtc to $GO2RTC"
    mkdir -p /usr/local/go2rtc/bin
    cd /usr/local/go2rtc/bin
    #Get latest release
    wget -O go2rtc "https://github.com/AlexxIT/go2rtc/releases/latest/download/go2rtc_linux_amd64"
    chmod +x go2rtc
    msg_ok "Updated go2rtc"

    msg_info "Starting go2rtc"
    systemctl start go2rtc.service
    msg_ok "Started go2rtc"
    msg_ok "$GO2RTC Update Successful"
    exit
  fi
  #Update ffmpeg
  if [ "$UPD" == "3" ]; then
    msg_info "Stopping Frigate and go2rtc"
    systemctl stop frigate.service go2rtc.service
    msg_ok "Stopped Frigate and go2rtc"

    msg_info "Updating ffmpeg to $FFMPEG"
    apt install xz-utils
    mkdir -p /usr/lib/btbn-ffmpeg
    wget -qO btbn-ffmpeg.tar.xz "https://github.com/BtbN/FFmpeg-Builds/releases/latest/download/ffmpeg-n6.1-latest-linux64-gpl-6.1.tar.xz"
    tar -xf btbn-ffmpeg.tar.xz -C /usr/lib/btbn-ffmpeg --strip-components 1
    rm -rf btbn-ffmpeg.tar.xz /usr/lib/btbn-ffmpeg/doc /usr/lib/btbn-ffmpeg/bin/ffplay
    msg_ok "Updated ffmpeg"

    msg_info "Starting Frigate and go2rtc"
    systemctl start frigate.service go2rtc.service
    msg_ok "Started Frigate and go2rtc"
    msg_ok "$FFMPEG Update Successful"
    exit
  fi
}

start
build_container
description

msg_info "Setting Container to Normal Resources"
pct set $CTID -memory 2048
pct set $CTID -cores 2
msg_ok "Set Container to Normal Resources"
msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:5000${CL}"