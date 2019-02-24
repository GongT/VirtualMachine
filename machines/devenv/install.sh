#!/usr/bin/env bash

source ../../lib/nspawn.sh
source ../../lib/systemd.sh

function prepare() {
	vm-use-network bridge
	vm-mount [root] data:/data
	vm-mount [root] dev/shm:/dev/shm
	vm-mount [root] dev/dri:/dev/dri
}

prepare-vm DevelopmentEnvironment prepare

mdnf DevelopmentEnvironment install git vim nmap-ncat tar xz gzip git hostname libXext findutils libXrender libXtst freetype 'wqy-*' rsync procps-ng
# TODO: mdnf link to dnf, copy .ssh from host

add-sshd

create-machine-service DevelopmentEnvironment > "$(system-service-file DevelopmentEnvironment)"
systemctl enable DevelopmentEnvironment.machine
systemctl daemon-reload
