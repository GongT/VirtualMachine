#!/usr/bin/env bash

echo webserver > /etc/hostname

cd /opt/config

for i in "pear" "php-fpm.d" "php.d" "pear.conf" "php.ini" "php-fpm.conf" "sysconfig/memcached" ; do
	TARGET="/etc/${i}"
	if [ -h "${TARGET}" ] ; then
		unlink "${TARGET}"
	elif [ -e "${TARGET}" ] ; then
		rm -r "${TARGET}"
	fi
	ln -s "/opt/config/${i}" "${TARGET}"
done

mkdir -p /var/log/nginx
mkdir -p /var/log/php-fpm

mkdir -p /usr/lib/systemd/system/nginx.service.d/
echo '[Service]
Restart=always
RestartSec=5
ExecStart=
ExecStart=/usr/sbin/nginx

[Unit]
StartLimitInterval=11
StartLimitBurst=2

' > /usr/lib/systemd/system/nginx.service.d/overwrite.conf