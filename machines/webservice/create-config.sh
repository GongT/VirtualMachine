#!/usr/bin/env bash

echo webserver > /etc/hostname

cd /opt/config

for i in "pear" "php-fpm.d" "php.d" "pear.conf" "php.ini" "php-fpm.conf" ; do
	TARGET="/etc/${i}"
	if [ -e "${TARGET}" ]; then
		if [ -h "${TARGET}" ] && [ ! -d "${TARGET}" ] ; then
			unlink "${TARGET}"
		else
			rm -r "${TARGET}"
		fi
		
		ln -s "/opt/config/${i}" "${TARGET}"
	fi
done

mkdir -p /var/log/nginx
