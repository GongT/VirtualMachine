#!/usr/bin/env sh

set -e
set -x


QB_TAR_FILE=$1
LIBT_TAR_FILE=$2

cd /opt

NP=$(( $(nproc) / 2 ))

# lib torrent
mkdir -p libtorrent
tar -xf "${LIBT_TAR_FILE}" --strip-components=1 -C ./libtorrent

pushd libtorrent &>/dev/null
./autotool.sh
# --enable-python-binding \
# --with-boost-python \
./configure --prefix=/usr --config-cache \
	--enable-examples=no \
	--enable-encryption \
	--with-boost-system \
	--with-boost-chrono \
	--with-boost-random \
	--with-libiconv \
	--with-gnu-ld \
	--enable-disk-stats

make -j${NP}
make install
popd &>/dev/null

# qBittorrent
mkdir -p source
tar -xf "${QB_TAR_FILE}" --strip-components=1 -C ./source

pushd source &>/dev/null

./configure --prefix=/opt/QB --config-cache --enable-systemd --disable-gui CPPFLAGS=-I/usr/include/qt5
make -j${NP}
make install

popd &>/dev/null
