#!/bin/sh

set -e

if ! [[ -e /var/lib/mysql/default_password ]]; then
	/usr/local/mysql/bin/mysqladmin -u root password "${DEFAULT_PASSWORD}" -h127.0.0.1
fi

