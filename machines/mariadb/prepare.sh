#!/usr/bin/env bash

if ! grep -q -- "mysql" /etc/passwd ; then
	useradd --user-group mysql
fi

mkdir -p /mnt/log/mariadb

chown -R mysql:mysql /var/lib/mysql
chown -R mysql:mysql /mnt/log/mariadb
chown -R mysql:mysql /usr/local/mysql

mkdir -p /mnt/socket/mysqld
chown -R mysql:mysql /mnt/socket/mysqld
