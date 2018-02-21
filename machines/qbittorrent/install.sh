#!/usr/bin/env bash

source ../../lib/nspawn.sh
source ../../lib/systemd.sh

QB_RELEASE=https://github.com/qbittorrent/qBittorrent/archive/release-4.0.4.tar.gz
LIBT_RELEASE=https://github.com/arvidn/libtorrent/archive/libtorrent-1_1_6.tar.gz

function prepare() {
	vm-use-network bridge
	vm-mount [config] /opt/qBittorrent/config/
	vm-mount [app] /opt/qBittorrent/data
	vm-mount [volumes] /data/Volumes/
}

prepare-vm qbittorrent prepare
if ! vm-command-exits qbittorrent /usr/bin/libtool ; then
	mdnf qbittorrent install \
		make gcc-c++ pkgconf-pkg-config autoconf automake libtool \
		tar openssh openssh-server \
		qt-devel boost-devel openssl-devel qt5-qtbase-devel qt5-linguist
fi

vm-copy qbittorrent qbittorrent.service /etc/systemd/system/
vm-systemctl qbittorrent enable qbittorrent.service

QB_TARGET=$(vm-file qbittorrent /opt/qbittorrent.tar.gz)
if [ ! -e "${QB_TARGET}" ] ; then
	wget -c "${QB_RELEASE}" -O "${QB_TARGET}.downloading"
	mv "${QB_TARGET}.downloading" "${QB_TARGET}"
fi
LIBT_TARGET=$(vm-file qbittorrent /opt/libtorrent.tar.gz)
if [ ! -e "${LIBT_TARGET}" ] ; then
	wget -c "${LIBT_RELEASE}" -O "${LIBT_TARGET}.downloading"
	mv "${LIBT_TARGET}.downloading" "${LIBT_TARGET}"
fi
screen-run vm-script qbittorrent compile.sh "$(basename "${QB_TARGET}")" "$(basename "${LIBT_TARGET}")"

CONFIG_PATH="$(vm-mount-type [config])/qBittorrent/qBittorrent.conf"
if [ ! -e "${CONFIG_PATH}" ]; then
	mkdir -p "$(dirname "${CONFIG_PATH}")"
	echo "[Preferences]
WebUI\Enabled=true
" > ${CONFIG_PATH}
fi

create-machine-service qbittorrent > "$(system-service-file qbittorrent)"
systemctl enable qbittorrent.machine
systemctl daemon-reload
