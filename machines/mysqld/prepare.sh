#!/usr/bin/env bash

echo "" | useradd mysql || true

touch /var/run/socket/mysql.sock
chown mysql:mysql /var/run/socket/mysql.sock
chmod 0777 /var/run/socket/mysql.sock

chown -R mysql:mysql /var/lib/mysql
chown -R mysql:mysql /var/log/mariadb
