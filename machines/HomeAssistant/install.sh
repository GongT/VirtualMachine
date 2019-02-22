#!/usr/bin/env bash

source ../../lib/nspawn.sh
source ../../lib/systemd.sh

function prepare() {
	vm-use-network bridge
	# vm-mount ReadOnly [root] etc:/host/etc
	vm-mount [config] /etc/hass
}

prepare-vm home-assistant prepare
create-machine-service home-assistant > "$(system-service-file home-assistant)"

cp -r "$(vm-mount-type [install])/hass/." "$(vm-mount-type [config])"
mkdir -p "$(vm-mount-type [config])/deps"

mdnf home-assistant install python3 python3-devel redhat-rpm-config gcc mosquitto wget tar yarn npm

if [ ! -e "$(vm-file home-assistant opt/home-assistant/.git)" ]; then
	git clone https://github.com/home-assistant/home-assistant.git "$(vm-file home-assistant opt/home-assistant)"
fi
if [ ! -e "$(vm-file home-assistant opt/home-assistant-frontend/.git)" ]; then
	git clone https://github.com/home-assistant/home-assistant-polymer.git "$(vm-file home-assistant opt/home-assistant-frontend)"
fi

echo "ha" > "$(vm-file home-assistant etc/hostname)"

vm-script home-assistant ha-install.sh

systemctl enable home-assistant.machine
systemctl daemon-reload

echo "OK"
