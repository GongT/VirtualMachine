#!/usr/bin/env bash

source ../../lib/nspawn.sh
source ../../lib/systemd.sh

function prepare() {
	vm-use-network bridge
	vm-mount [root] data:/data
}

prepare-vm DevelopmentEnvironment prepare
if ! vm-command-exits DevelopmentEnvironment /usr/sbin/sshd ; then
	mdnf DevelopmentEnvironment install openssh-server
fi
vm-systemctl DevelopmentEnvironment enable sshd

vm-copy DevelopmentEnvironment config/sshd_config /etc/ssh/
cp ~/.ssh/authorized_keys $(vm-file DevelopmentEnvironment /root/.ssh/)

create-machine-service DevelopmentEnvironment > "$(system-service-file DevelopmentEnvironment)"
systemctl enable DevelopmentEnvironment.machine
systemctl daemon-reload
