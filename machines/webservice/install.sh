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

cp -vr "$(vm-mount-type [install])/config/." "$(vm-mount-type [config])"

vm-script webservice pre-install.sh

function do-install-server() {
	{
		echo "update"
		cat "$(staff-file packages.lst)" | sed '#^$#d' | sed 's#^#install #'
		echo "run"
		echo "exit"
	} | mdnf webservice shell
}
screen-run do-install-server

screen-run mdnf build-env install -y $(<"$(staff-file dependencies.lst)")

# dnf config-manager --add-repo https://openresty.org/package/fedora/openresty.repo

set -e

vm-copy webservice memcached@.service /etc/systemd/system/
vm-script webservice create-config.sh

screen-run vm-script build-env build-php.sh
cp -r "$(vm-file build-env "/opt/php/modules/.")" "$(vm-file webservice "/usr/lib64/php/modules")"
cp -r "$(vm-file build-env "/opt/php/config/.")" "$(vm-mount-type [config])/php.d"

screen-run host-script build-env download-source.sh
screen-run vm-script build-env build-nginx.sh

cp -r "$(vm-file build-env "/opt/nginx/nginx")" "$(vm-file webservice "/usr/sbin/nginx")"
cp -r "$(vm-file build-env "/opt/nginx/nginx.service")" "$(vm-file webservice "/usr/lib/systemd/system/nginx.service")"

host-script webservice install-projects.sh
vm-script webservice chown.sh

vm-systemctl webservice enable php-fpm nginx memcached@11211 memcached@11212 redis crond

create-machine-service webservice > "$(system-service-file webservice)"
systemctl enable webservice.machine
systemctl daemon-reload

echo "Success..."
