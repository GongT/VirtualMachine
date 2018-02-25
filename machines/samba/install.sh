#!/usr/bin/env bash

source ../../lib/nspawn.sh
source ../../lib/systemd.sh

function prepare() {
	vm-use-network bridge
	vm-mount [volumes] /drives
	vm-mount [root] data/DevelopmentRoot:/data/DevelopmentRoot
}

prepare-vm samba prepare || die "can not prepare vm"
if ! vm-command-exits samba /usr/sbin/smbd || \
   ! vm-command-exits samba /usr/sbin/ifconfig ; then
	screen-run mdnf samba install samba net-tools
fi

create-machine-service samba > "$(system-service-file samba)"
vm-copy samba create-config.sh /opt
vm-copy samba scripts/. /opt/.

if machinectl status samba &>/dev/null ; then
	systemd-run -M samba /bin/bash /opt/create-config.sh
else
	systemd-nspawn -M samba /bin/bash /opt/create-config.sh
fi

vm-systemctl samba enable smb nmb /opt/prepare.service

systemctl enable samba.machine
systemctl daemon-reload
