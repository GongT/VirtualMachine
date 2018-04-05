#!/usr/bin/env bash

source ../../lib/nspawn.sh
source ../../lib/systemd.sh

function prepare() {
	vm-use-network bridge
}

prepare-vm teaching prepare
mdnf teaching install gcc vim

create-machine-service teaching > "$(system-service-file teaching)"
systemctl enable teaching.machine
systemctl daemon-reload
