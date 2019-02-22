#!/usr/bin/env bash

source ../../lib/nspawn.sh
source ../../lib/systemd.sh

if [ -z "$HTTPS_PROXY" ]; then
	echo "proxy required"
	exit 1
fi
MARIADB_RELEASE="https://downloads.mariadb.org/f/mariadb-10.3.12/bintar-linux-glibc_214-x86_64/mariadb-10.3.12-linux-glibc_214-x86_64.tar.gz"

function prepare() {
	vm-use-network bridge
	vm-mount [app] /var/lib/mysql
	vm-mount [log] /var/log/mariadb
	vm-use-socket
}

prepare-vm mariadb prepare
mkdir -p "$(vm-mount-type [app])"

cp "$(staff-file my.cnf)" "$(vm-file mariadb etc/my.cnf)"
cp "$(staff-file mariadb.service)" "$(vm-file mariadb /usr/lib/systemd/system/mariadb.service)"
cp "$(staff-file prestart.sh)" "$(staff-file poststart.sh)" "$(vm-file mariadb /opt)"

screen-run mdnf mariadb install -y libaio numactl-libs libstdc++ ncurses-compat-libs

host-script mariadb install-mariadb.sh "${MARIADB_RELEASE}"
vm-script mariadb prepare.sh
vm-systemctl mariadb enable mariadb.service

create-machine-service mariadb > "$(system-service-file mariadb)"

systemctl enable mariadb.machine
systemctl daemon-reload

echo "Success..."
