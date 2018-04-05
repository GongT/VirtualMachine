#!/usr/bin/env bash

source ../../lib/nspawn.sh
source ../../lib/systemd.sh

function prepare() {
	vm-use-network bridge
	vm-mount [volumes] /data/Volumes/
}

prepare-vm android prepare
mdnf android install openssh-server \
	bc bison ImageMagick curl flex gnupg gperf xz-lzma-compat \
	libxml2 lzop pngcrush schedtool squashfs-tools zip \
	zip curl gcc gcc-c++ flex bison gperf glibc-devel zlib-devel \
	ncurses-devel libX11-devel libstdc++ readline-devel libXrender \
	libXrandr perl-Digest-MD5-File python-markdown mesa-libGL-devel \
	git schedtool pngcrush ncurses-compat-libs java-1.8.0-openjdk-devel

vm-copy android config/sshd_config /etc/ssh/
cp ~/.ssh/authorized_keys $(vm-file android /root/.ssh/)
vm-systemctl android enable sshd.service

create-machine-service android > "$(system-service-file android)"
systemctl daemon-reload

