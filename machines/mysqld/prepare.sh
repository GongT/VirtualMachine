#!/usr/bin/env bash

echo "" | useradd mysql || true


mkdir -p /var/run/socket/mysqld

chown -R mysql:mysql /var/lib/mysql/
chown -R mysql:mysql /var/log/mariadb/
chown -R mysql:mysql /usr/local/mysql/
chown -R mysql:mysql /var/run/socket/mysqld

