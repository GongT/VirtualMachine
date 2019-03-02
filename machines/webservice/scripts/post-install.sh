#!/usr/bin/env bash

set -e
echo "Post install script."

mkdir -p /mnt/log/nginx
mkdir -p /mnt/log/php-fpm

function remove() {
	local P="$1"
	if [[ -L "$P" ]]; then
		unlink "$P"
	elif [[ -e "$P" ]]; then
		rm -rf "$P"
	fi
}

function php_user_chown() {
	if ! [[ -e "$2" ]]; then
		echo "Warning: $2 did not exists."
		mkdir -p "$2"
	fi
	echo "Fix permissions on directory $2"
	chown -R "$1:$1" "$2"
	find "$2" -type d -exec chmod 0755 '{}' \;
	find "$2" -type f -exec chmod 0644 '{}' \;
}

### link phpmyadmin config to /mnt/config/pma
remove /opt/phpMyAdmin/working/config
remove /opt/phpMyAdmin/working/config.inc.php
remove /opt/phpMyAdmin/working/setup
remove /opt/phpMyAdmin/setuptool/config
remove /opt/phpMyAdmin/setuptool/config.inc.php

ln -s /mnt/config/phpMyAdmin /opt/phpMyAdmin/setuptool/config
ln -s /mnt/config/phpMyAdmin/config.inc.php /opt/phpMyAdmin/working/config.inc.php

### same with nextcloud
remove /opt/nextcloud/config
ln -s /mnt/config/nextcloud /opt/nextcloud/config

### same with pdns admin
remove /opt/poweradmin/install
remove /opt/poweradmin/config.inc.php
ln -s /mnt/config/poweradmin/config.inc.php /opt/poweradmin/config.inc.php
remove /opt/poweradmin/inc/config.inc.php
ln -s /mnt/config/poweradmin/config.inc.php /opt/poweradmin/inc/config.inc.php

### add nginx user
function add_user_if() {
	echo "Create user $1"
	if ! grep -q -- "$1" /etc/passwd ; then
		useradd --user-group "$1"
	fi
}
add_user_if nginx
add_user_if nextcloud
add_user_if wordpress
add_user_if phpmyadmin
add_user_if poweradmin
add_user_if nobody-1
add_user_if nobody-2
add_user_if nobody-3
add_user_if nobody-4
add_user_if nobody-5

### create static things
mkdir -p /opt/phpinfo
echo '<?php echo phpinfo();' > /opt/phpinfo/phpinfo.php
php_user_chown nginx /opt/phpinfo

mkdir -p /opt/nginx

echo "Generating new nginx password file..."
{
	echo -n 'Administrator:'
	openssl passwd -apr1 "$PASSWORD"
} > /opt/nginx/htpasswd

CERT_FILE=/opt/nginx/self-signed.crt
KEY_FILE=/opt/nginx/self-signed.key
echo "Generating new nginx cert file..."
openssl req -batch -x509 -nodes -days 365 -newkey rsa:2048 -keyout "$KEY_FILE" -out "$CERT_FILE"

mkdir -p /data/redis
php_user_chown redis /data/redis

### chown of common things
php_user_chown nginx /opt/nginx
php_user_chown nginx /run/socket/php-fpm
php_user_chown nginx /mnt/log/nginx
php_user_chown nginx /mnt/log/php-fpm
php_user_chown nextcloud /mnt/log/nextcloud

### chown for web contents
php_user_chown nextcloud /opt/nextcloud
php_user_chown nextcloud /drives/AppData/NextCloud
php_user_chown phpmyadmin /opt/phpMyAdmin
php_user_chown poweradmin /opt/poweradmin
php_user_chown wordpress /opt/wordpress
php_user_chown phpmyadmin /drives/AppData/Backups/phpMyAdmin

