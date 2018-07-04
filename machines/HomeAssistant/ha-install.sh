#!/usr/bin/env bash

set -e

export HTTP_PROXY="http://proxy-server:8080"
export HTTPS_PROXY="${HTTP_PROXY}"

cd /opt/home-assistant-frontend

echo "installing nvm..."
wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.33.11/install.sh | bash

export NVM_DIR="$HOME/.nvm"
function load_nvm() {
	[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh" || echo "nvm load failed"
}
load_nvm
echo "installing nodejs..."
nvm install
echo "activating nodejs..."
nvm use
echo "installing node_modules..."
npm install -g yarn
yarn
echo "running develop script..."
script/build_frontend

echo "[Unit]
Description=Home Assistant
After=network-online.target

[Service]
Type=simple
WorkingDirectory=/opt/home-assistant
ExecStartPre=/bin/bash -c 'mountpoint /etc/hass/deps || mount --bind /opt /etc/hass/deps'
ExecStart=/usr/bin/env python3 -m homeassistant --config /etc/hass

[Install]
WantedBy=multi-user.target" > /usr/lib/systemd/system/hass.service

systemctl enable hass.service mosquitto.service