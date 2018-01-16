#!/usr/bin/env bash

source ../../lib/nspawn.sh
source ../../lib/systemd.sh

function prepare() {
	vm-use-network bridge
	vm-mount ReadOnly [root] etc:/host/etc
	vm-mount ReadOnly [share] letsencrypt:/etc/letsencrypt
}

prepare-vm homedns prepare
if ! vm-command-exits homedns /usr/sbin/named \
|| ! vm-command-exits homedns /usr/bin/nslookup ; then
	mdnf homedns install bind bind-utils
fi
vm-systemctl homedns enable named

create-machine-service homedns > "$(system-service-file homedns)"
vm-script homedns create-config.sh

systemctl enable homedns.machine
systemctl daemon-reload
