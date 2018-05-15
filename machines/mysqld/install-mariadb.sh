#!/usr/bin/env bash

cd opt

download-file "mariadb-server.tar.gz" "$1" || die "can not download mariadb"
mkdir -p ../usr/local/mysql
tar -xf "mariadb-server.tar.gz" --strip-components=1 -C ../usr/local/mysql
