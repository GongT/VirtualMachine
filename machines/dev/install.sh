#!/usr/bin/env bash

source ../../lib/nspawn.sh
source ../../lib/systemd.sh

function prepare() {
	vm-use-network bridge
	vm-mount [root] data:/data
}

prepare-vm DevelopmentEnvironment prepare

add-sshd

create-machine-service DevelopmentEnvironment > "$(system-service-file DevelopmentEnvironment)"
systemctl enable DevelopmentEnvironment.machine
systemctl daemon-reload
