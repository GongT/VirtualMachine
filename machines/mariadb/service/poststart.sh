#!/bin/sh

set -e

if ! [[ -e /var/lib/mysql/default_password ]]; then
	echo "Setting default password"
	/usr/bin/mysqladmin -u root password "${DEFAULT_PASSWORD}" -h127.0.0.1
	echo "${DEFAULT_PASSWORD}" > /var/lib/mysql/default_password
fi
