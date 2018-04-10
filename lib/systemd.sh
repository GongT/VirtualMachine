#!/usr/bin/env bash


function system-service-file() {
	echo "/etc/systemd/system/$1.machine.service"
}

function create-machine-service() {
	local MACHINE=$1
	echo "[Unit]
Description=systemd.nspawn container $MACHINE
Documentation=man:systemd-nspawn(1)
PartOf=machines.target
Before=machines.target
After=network.target systemd-resolved.service systemd-networkd.service"
	for i in "${HOST_FOLDERS[@]}" ; do
		echo "RequiresMountsFor=\"$i\""
	done
echo "
[Install]
WantedBy=machines.target

[Service]
Environment=MACHINE=$MACHINE
ExecStartPre=/bin/bash -c \"cat '$(vm-file "${MACHINE}" .binddir)' | xargs mkdir -vp || true\"
ExecStartPre=-/usr/bin/machinectl terminate \$MACHINE
ExecStart=/usr/bin/systemd-nspawn --settings=trusted --machine \$MACHINE
ExecReload=/usr/bin/systemctl --machine \$MACHINE restart dnsmasq
ExecStop=/usr/bin/systemctl --machine \$MACHINE poweroff
KillSignal=SIGINT
KillMode=mixed
Type=notify
Slice=machine.slice
Delegate=yes
Restart=on-failure

LimitNOFILE=infinity
LimitMEMLOCK=infinity
OOMScoreAdjust=-1000

TimeoutStopSec=60s
RestartSec=10s
"
}
