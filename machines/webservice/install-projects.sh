#!/usr/bin/env bash

PMA_URL="https://files.phpmyadmin.net/phpMyAdmin/4.8.0/phpMyAdmin-4.8.0-all-languages.zip"
PMA_NAME="$(basename -s .zip "$PMA_URL")"

cd opt
download-file "phpmyadmin.zip" "${PMA_URL}" || die "can not download mariadb"
if [ ! -e "phpMyAdmin/${PMA_NAME}" ]; then
	mv phpMyAdmin/ phpMyAdmin.bak/
	mkdir -p phpMyAdmin/
	
	unzip -d phpMyAdmin "phpmyadmin.zip"
	mv phpMyAdmin/*/* phpMyAdmin/
	
	rm -rf phpMyAdmin/config/
	mv phpMyAdmin.bak/config/ phpMyAdmin/config/
	rm -rf phpMyAdmin.bak
fi
mkdir -p phpMyAdmin/config
chmod 0777 phpMyAdmin/config

