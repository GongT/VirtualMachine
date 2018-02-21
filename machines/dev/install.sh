#!/usr/bin/env bash

source ../../lib/nspawn.sh
source ../../lib/systemd.sh

function prepare() {
	vm-use-network bridge
	vm-mount [root] data:/data
}

prepare-vm DevelopmentEnvironment prepare
if ! vm-command-exits DevelopmentEnvironment /usr/sbin/sshd ; then
	mdnf DevelopmentEnvironment install openssh-server
fi
vm-systemctl DevelopmentEnvironment enable sshd

# vm-copy qbittorrent qbittorrent.service /etc/systemd/system/
# vm-systemctl qbittorrent enable qbittorrent.service

create-machine-service DevelopmentEnvironment > "$(system-service-file DevelopmentEnvironment)"
systemctl enable DevelopmentEnvironment.machine
systemctl daemon-reload
