#!/usr/bin/env bash

KCPTUN_RELEASE=https://github.com/xtaci/kcptun/releases/download/v20171201/kcptun-linux-amd64-20171201.tar.gz
SHADOWSOCKS_RELEASE=https://github.com/shadowsocks/shadowsocks-libev/releases/download/v3.1.3/shadowsocks-libev-3.1.3.tar.gz

source ../../lib/nspawn.sh
source ../../lib/systemd.sh

function prepare() {
	vm-use-network bridge
	vm-mount [config] /config
}

prepare-vm proxy-server prepare

### basic files
mkdir -p "$(vm-file proxy-server /data/config)"
cat config/kcptun.json | \
	sed "s/\$SS_PASSWORD/$SS_PASSWORD/g" | \
	sed "s/\$SS_SERVER/$SS_SERVER/g"|  \
	sed "s/\$KCP_PORT/$KCP_PORT/g" \
	> "$(vm-file proxy-server /data/config/kcptun.json)"
cat config/shadowsocks.json | \
	sed "s/\$SS_PASSWORD/$SS_PASSWORD/g" | \
	sed "s/\$SS_METHOD/${SS_METHOD-"rc4-md5"}/g" \
	> "$(vm-file proxy-server /data/config/shadowsocks.json)"

vm-copy proxy-server config/vnstat.conf /etc

vm-copy proxy-server services/. /usr/lib/systemd/system
vm-systemctl proxy-server enable kcptun.service shadowsocks.service

if ! vm-command-exits proxy-server /usr/bin/gcc ; then
	screen-run mdnf proxy-server install samba sed wget make tar file gcc-c++ \
		pcre-devel mbedtls-devel libsodium-devel c-ares-devel libev-devel
fi

### privoxy
if ! vm-command-exits proxy-server /usr/bin/privoxy ; then
	screen-run mdnf proxy-server install privoxy
fi
screen-run vm-script proxy-server prepare-config.sh
vm-systemctl proxy-server enable privoxy.service nmb.service
HOST_FILE_CONFIG="$(vm-mount-type "[config]")/user.action"
if [ ! -e "${HOST_FILE_CONFIG}" ]; then
	echo '{+forward-override{forward-socks5 127.0.0.1:7070 .} }' > "${HOST_FILE_CONFIG}"
fi

### shadowsocks
if ! vm-command-exits proxy-server /data/shadowsocks/bin/ss-local ; then
	vm-script proxy-server install-ss.sh "${SHADOWSOCKS_RELEASE}"
fi

### kcptun
if ! vm-command-exits proxy-server /data/kcptun/client_linux_amd64 ; then
	screen-run host-script proxy-server install-kcp.sh "${KCPTUN_RELEASE}"
fi

### vnstat
if ! vm-command-exits proxy-server /usr/bin/vnstat ; then
	screen-run mdnf proxy-server install vnstat
fi
vm-systemctl proxy-server enable vnstat.service

### complete
create-machine-service proxy-server > "$(system-service-file proxy-server)"
systemctl enable --now proxy-server.machine.service
systemctl daemon-reload
