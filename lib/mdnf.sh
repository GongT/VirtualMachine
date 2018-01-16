#!/usr/bin/env bash

function mdnf() {
	local MACHINE="${LIB_MACHINE}/$1"
	if [ ! -d "$MACHINE" ]; then
			echo "No such machine: $1" >&2
			exit 1
	fi
	shift
	
	/usr/bin/dnf -y \
		   --setopt=cachedir=../../../../../../../../../../../../../../../var/cache/dnf \
		   --setopt=config_file_path=/etc/dnf/dnf.conf \
		   --setopt=reposdir=/etc/yum.repos.d \
		   --releasever=/ --installroot="${MACHINE}" "$@"
}
