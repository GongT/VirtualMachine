#!/usr/bin/env bash

source ../../lib/nspawn.sh
source ../../lib/systemd.sh

function prepare() {
	vm-use-network bridge
	# vm-mount ReadOnly [root] etc:/host/etc
	vm-mount [config] dnsmasq:/etc/dnsmasq.d
	vm-mount ReadOnly [share] letsencrypt:/etc/letsencrypt
}

prepare-vm homedns prepare
if ! vm-command-exits homedns /usr/sbin/named \
|| ! vm-command-exits homedns /usr/bin/nslookup \
|| ! vm-command-exits homedns /usr/sbin/dnsmasq ; then
	mdnf homedns install bind bind-utils dnsmasq
fi
vm-systemctl homedns enable named dnsmasq

create-machine-service homedns > "$(system-service-file homedns)"
vm-script homedns create-config.sh

systemctl enable homedns.machine
systemctl daemon-reload
