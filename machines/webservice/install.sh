#!/usr/bin/env bash

source ../../lib/nspawn.sh
source ../../lib/systemd.sh

function prepare() {
	vm-use-network bridge
	vm-temp /tmp
	vm-mount [source] /data
	vm-mount ReadOnly [share] letsencrypt:/etc/letsencrypt
	vm-mount ReadOnly [install] config:/opt/config
	vm-mount [log] /var/log
	vm-use-socket
}

prepare-vm webservice prepare

vm-script webservice pre-install.sh

function do-install-server() {
	{
		echo "update"
		cat "$(staff-file packages.lst)" | sed '#^$#d' | sed 's#^#install #'
		echo "reinstall nginx"
		echo "run"
		echo "exit"
	} | mdnf webservice shell
	
	vm-systemctl webservice enable php-fpm nginx memcached
}
screen-run do-install-server

create-machine-service webservice > "$(system-service-file webservice)"

vm-script webservice create-config.sh

screen-run mdnf build-env install -y $(<"$(staff-file dependencies.lst)")
host-script build-env download-source.sh
vm-script build-env build-nginx.sh "$(vm-script webservice nginx-compile-args.sh)"

mkdir -p "$(vm-file webservice "/opt/modules/")"
cp -r "$(vm-file build-env "/opt/nginx/dist/.")" "$(vm-file webservice "/opt/modules")"
screen-run vm-script webservice cleanup.sh

systemctl enable webservice.machine
systemctl daemon-reload
