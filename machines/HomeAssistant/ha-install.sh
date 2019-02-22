#!/usr/bin/env bash

set -e

if [ -z "$HTTPS_PROXY" ]; then
	echo "proxy required"
	exit 1
fi

cd /opt/home-assistant-frontend

echo "installing node_modules..."
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