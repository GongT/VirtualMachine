#!/usr/bin/env bash

echo webserver > /etc/hostname

cd /opt/config

for i in "pear" "php-fpm.d" "php.d" "pear.conf" "php.ini" "php-fpm.conf" ; do
	TARGET="/etc/${i}"
	if [ -e "${TARGET}" ]; then
		if [ -h "${TARGET}" ] ; then
			unlink "${TARGET}"
		else
			rm -r "${TARGET}"
		fi
	fi
	ln -s "/opt/config/${i}" "${TARGET}"
done

mkdir -p /var/log/nginx
mkdir -p /var/log/php-fpm
