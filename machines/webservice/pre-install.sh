#!/usr/bin/env bash

set -e

for i in "pear" "php-fpm.d" "php.d" "pear.conf" "php.ini" "php-fpm.conf" ; do
	TARGET="/etc/${i}"
	if [ -h "${TARGET}" ]; then
		unlink "${TARGET}"
	fi
done
