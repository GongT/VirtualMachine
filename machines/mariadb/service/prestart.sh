#!/bin/sh

set -e

mkdir -p /var/run/socket/mysqld
chown mysql:mysql /var/run/socket/mysqld

mkdir -p /var/run/mysqld
chown mysql:mysql /var/run/mysqld

