#!/usr/bin/env bash

source ../../lib/nspawn.sh
source ../../lib/systemd.sh

MARIADB_RELEASE="https://downloads.mariadb.org/f/mariadb-10.2.14/bintar-linux-glibc_214-x86_64/mariadb-10.2.14-linux-glibc_214-x86_64.tar.gz"

function prepare() {
	vm-use-network bridge
	vm-mount [app] /var/lib/mysql
	vm-mount [log] /var/log/mariadb
	vm-use-socket
}

prepare-vm mysqld prepare

cp "$(staff-file my.cnf)" "$(vm-file mysqld etc/my.cnf)"
cp "$(staff-file mariadb.service)" "$(vm-file mysqld /usr/lib/systemd/system/mariadb.service)"

screen-run mdnf mysqld install -y libaio numactl-libs libstdc++

host-script mysqld install-mariadb.sh "${MARIADB_RELEASE}"
vm-script mysqld prepare.sh
vm-systemctl mysqld enable mariadb.service

create-machine-service mysqld > "$(system-service-file mysqld)"

systemctl enable mysqld.machine
systemctl daemon-reload

echo "Success..."
