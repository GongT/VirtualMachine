#!/usr/bin/env bash

set -e

if ! [[ -e /mnt/log/hass ]]; then
	mkdir -p /mnt/log/hass
fi

if ! [[ -e /opt/home-assistant-deps ]]; then
	mkdir -p /opt/home-assistant-deps
fi

if ! mountpoint /etc/hass/deps ; then
	echo "Bind /etc/hass/deps with /opt/home-assistant-deps"
	mount --bind /opt/home-assistant-deps /etc/hass/deps
fi
