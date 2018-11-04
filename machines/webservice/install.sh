#!/usr/bin/env bash


source ../../lib/nspawn.sh
source ../../lib/systemd.sh

function prepare() {
	vm-use-network bridge
	vm-temp /tmp
	vm-mount [app] /data
	vm-mount [source] /data/DevelopmentRoot
	vm-mount ReadOnly [share] letsencrypt:/etc/letsencrypt
	vm-mount ReadOnly [config] /opt/config
	vm-mount [log] /var/log
	vm-mount [volumes] /drives
	vm-mount [slowCache] /data/slowCache
	vm-use-socket
}

prepare-vm webservice prepare

cp -r "$(vm-mount-type [install])/config/." "$(vm-mount-type [config])"

vm-script webservice pre-install.sh

function do-install-server() {
	{
		echo "update"
		cat "$(staff-file packages.lst)" | sed '#^$#d' | sed 's#^#install #'
		echo "reinstall nginx"
		echo "run"
		echo "exit"
	} | mdnf webservice shell
}
screen-run do-install-server

set -e

vm-systemctl webservice enable php-fpm nginx memcached redis crond

create-machine-service webservice > "$(system-service-file webservice)"

vm-script webservice create-config.sh

screen-run mdnf build-env install -y $(<"$(staff-file dependencies.lst)")
screen-run host-script build-env download-source.sh
screen-run vm-script build-env build-nginx.sh "$(vm-script webservice nginx-compile-args.sh)"

vm-mkdir webservice "/opt/modules/"
cp -r "$(vm-file build-env "/opt/nginx/dist/.")" "$(vm-file webservice "/opt/modules")"
screen-run vm-script webservice cleanup.sh

host-script webservice install-projects.sh
vm-script webservice chown.sh

systemctl enable webservice.machine
systemctl daemon-reload

echo "Success..."
