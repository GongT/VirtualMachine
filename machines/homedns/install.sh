#!/usr/bin/env bash

source ../../lib/nspawn.sh
source ../../lib/systemd.sh

function prepare() {
	vm-use-network bridge
	# vm-mount ReadOnly [root] etc:/host/etc
	vm-mount [config] /opt/config
	vm-mount ReadOnly [share] letsencrypt:/etc/letsencrypt
	vm-use-socket
}

prepare-vm homedns prepare
if ! vm-command-exits homedns /usr/sbin/pdns_server \
|| ! vm-command-exits homedns /usr/bin/nslookup \
|| ! vm-command-exits homedns /usr/sbin/dnsmasq ; then
	screen-run mdnf homedns install bind-utils dnsmasq \
				pdns pdns-tools pdns-backend-mysql
fi

create-machine-service homedns > "$(system-service-file homedns)"

cp -rv "$(staff-file "etc/.")" "$(vm-mount-type [config])"

vm-script homedns create-etc-links.sh

vm-systemctl homedns reenable dnsmasq pdns

systemctl enable homedns.machine
systemctl daemon-reload
