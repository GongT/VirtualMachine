#!/bin/sh

set -x
set -e

if [ ! -e /var/lib/mysql/default_password ]; then
	PASSWD='Ezreal_LOL'
	/usr/local/mysql/bin/mysqladmin -u root password "${PASSWD}" -h127.0.0.1
	echo "${PASSWD}" > /var/lib/mysql/default_password
fi

