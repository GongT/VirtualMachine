#!/usr/bin/env bash

set -e

echo "Resolving DNS: home.gongt.me..."
IP_ADDR=$(dig +short home.gongt.me -p8805 @10.0.0.1)
echo "IP Address = $IP_ADDR"

CONFIG="/opt/qBittorrent/config/qBittorrent.conf"
cat "$CONFIG" | sed '/^Connection\\InetAddress=/d' | sed "/^\[Preferences\]/a Connection\\InetAddress=$IP_ADDR" > /tmp/qbt-config.temp
cat "/tmp/qbt-config.temp" > "$CONFIG"
