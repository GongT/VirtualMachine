#!/bin/sh

set -x
set -e

mkdir -p /var/run/mysqld
chown mysql:mysql /var/run/mysqld -R 

if [ ! -e /var/lib/mysql/performance_schema ]; then
	/usr/local/mysql/scripts/mysql_install_db -u mysql --basedir=/usr/local/mysql
	/usr/local/mysql/bin/mysqladmin -u root password 'Ezreal_LOL'
fi




