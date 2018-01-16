#!/usr/bin/env bash

source ../../lib/nspawn.sh
source ../../lib/systemd.sh

function prepare() {
	vm-use-network bridge
	vm-temp /var/lib/nginx/tmp
	vm-mount ReadOnly [source] .:/data/DevelopmentRoot
	vm-mount ReadOnly [share] letsencrypt:/etc/letsencrypt
}

prepare-vm webservice prepare
{
	cat "$(staff-file packages.lst)" | sed 's#^#install #'
	echo "run"
	echo "exit"
} | mdnf webservice shell
vm-systemctl webservice enable php-fpm nginx memcached

create-machine-service webservice > "$(system-service-file webservice)"
vm-script webservice create-config.sh

systemctl enable webservice.machine
systemctl daemon-reload
