#!/usr/bin/env bash


# phpMyAdmin
PMA_URL="https://files.phpmyadmin.net/phpMyAdmin/4.8.4/phpMyAdmin-4.8.4-all-languages.zip"
PMA_NAME="$(basename -s .zip "$PMA_URL")"

cd opt
# !!!!!!!

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


# NextCloud
NEXTCLOUD_RELEASE=https://download.nextcloud.com/server/releases/latest.tar.bz2

download-file "nextcloud.tar.bz2" "${NEXTCLOUD_RELEASE}" || die "can not download nextcloud"
tar xf nextcloud.tar.bz2
