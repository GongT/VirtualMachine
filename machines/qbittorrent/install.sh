#!/usr/bin/env bash

source ../../lib/nspawn.sh
source ../../lib/systemd.sh

QB_RELEASE=https://github.com/qbittorrent/qBittorrent/archive/release-4.1.4.tar.gz
LIBT_RELEASE=https://github.com/arvidn/libtorrent/releases/download/libtorrent_1_1_11/libtorrent-rasterbar-1.1.11.tar.gz

function prepare() {
	vm-use-network bridge
	vm-mount [config] /opt/qBittorrent/config/
	vm-mount [app] /opt/qBittorrent/data
	vm-mount [volumes] /data/Volumes/
}

prepare-vm qbittorrent prepare
mdnf qbittorrent install \
	make gcc-c++ pkgconf-pkg-config autoconf automake libtool \
	tar openssh openssh-server tigervnc-server i3 \
	qt-devel boost-devel openssl-devel qt5-qtbase-devel qt5-linguist qt5-qtsvg-devel

## enable ssh
add-sshd

## services
vm-copy qbittorrent qbittorrent.service /etc/systemd/system/
vm-copy qbittorrent xvnc0.service /etc/systemd/system/
vm-copy qbittorrent i3.service /etc/systemd/system/
vm-systemctl qbittorrent enable qbittorrent i3 xvnc0

## compile
QB_TARGET=$(vm-file qbittorrent "/opt/$(basename "$QB_RELEASE")")
if [ ! -e "${QB_TARGET}" ] ; then
	wget -c "${QB_RELEASE}" -O "${QB_TARGET}.downloading"
	mv "${QB_TARGET}.downloading" "${QB_TARGET}"
fi
LIBT_TARGET=$(vm-file qbittorrent "/opt/$(basename "$LIBT_RELEASE")")
if [ ! -e "${LIBT_TARGET}" ] ; then
	wget -c "${LIBT_RELEASE}" -O "${LIBT_TARGET}.downloading"
	mv "${LIBT_TARGET}.downloading" "${LIBT_TARGET}"
fi
screen-run vm-script qbittorrent compile.sh "$(basename "${QB_TARGET}")" "$(basename "${LIBT_TARGET}")"

## default config
CONFIG_PATH="$(vm-mount-type [config])/qBittorrent/qBittorrent.conf"
if [ ! -e "${CONFIG_PATH}" ]; then
	mkdir -p "$(dirname "${CONFIG_PATH}")"
	echo "[Preferences]
WebUI\Enabled=true
" > ${CONFIG_PATH}
fi

## finish
create-machine-service qbittorrent > "$(system-service-file qbittorrent)"
systemctl enable qbittorrent.machine
systemctl daemon-reload
