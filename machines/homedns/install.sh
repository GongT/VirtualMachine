#!/usr/bin/env bash

source ../../lib/nspawn.sh
source ../../lib/systemd.sh

function prepare() {
	vm-use-network bridge
	# vm-mount ReadOnly [root] etc:/host/etc
	vm-mount [config] /opt/config
	vm-mount ReadOnly [share] letsencrypt:/etc/letsencrypt
}

prepare-vm homedns prepare
if ! vm-command-exits homedns /usr/sbin/named \
|| ! vm-command-exits homedns /usr/bin/nslookup \
|| ! vm-command-exits homedns /usr/sbin/dnsmasq ; then
	screen-run mdnf homedns install bind bind-utils dnsmasq
fi

create-machine-service homedns > "$(system-service-file homedns)"

cp -v $(staff-file "service/*.service") "$(vm-file "${MACHINE}" etc/systemd/system)"
cp -rv "$(staff-file "config/.")" "$(vm-mount-type [config])"

vm-systemctl homedns reenable named dnsmasq

systemctl enable homedns.machine
systemctl daemon-reload
