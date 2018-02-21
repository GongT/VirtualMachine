#!/usr/bin/env bash

NETWORK_SUBSYS=yes

function vm-use-network() {
	case "$1" in
	bridge)
		NETWORK_SUBSYS=yes
		echo -e "[Network]
Bridge=bridge0\n"
	;;
	host)
		NETWORK_SUBSYS=no
		echo -e "[Network]\n\n"
	;;
	*)
		die "unknown network type: $1"
	esac
}

function vm-temp() {
	echo -e "[Files]
TemporaryFileSystem=$1\n"
}

function vm-mount() {
	local TYPE=Bind
	if [ "$1" == "ReadOnly" ]; then
		TYPE=BindReadOnly
		shift
	fi

	local ROOT="$(vm-mount-type "$1")"
	local MAP="$2"
	
	local LOCAL="${MAP%%:*}"
	local REMOTE="${MAP##*:}"
	
	if [ "${LOCAL}" == "." ] || [ "${LOCAL}" == "${REMOTE}" ]; then
		LOCAL=
		MAP=":${REMOTE}"
	fi
	
	echo "${ROOT}/${LOCAL}" >> "$(vm-file "${MACHINE}" .binddir)"
	vm-mkdir "${MACHINE}" "${REMOTE}"
	
	echo -e "[Files]
${TYPE}=${ROOT}/${MAP}\n"
}

function vm-use-socket() {
	vm-mount [socket] /var/run/socket
}

function vm-mount-type() {
	case "$1" in
	\[config\])
		echo "/data/AppData/config/${MACHINE}"
	;;
	\[install\])
		echo "${INSTALL_ROOT}"
	;;
	\[app\])
		echo "/data/AppData/data/${MACHINE}"
	;;
	\[share\])
		echo "/data/AppData/share"
	;;
	\[log\])
		echo "/data/AppData/logs/${MACHINE}"
	;;
	\[socket\])
		echo "/data/AppData/share/socket"
	;;
	\[source\])
		echo "/data/DevelopmentRoot"
	;;
	\[volumes\])
		echo "/data/Volumes"
	;;
	\[root\])
		echo "/"
	;;
	*)
		die "unknown mount type: $1"
	esac
}

function vm-env() {
	echo -e "[Exec]
Environment=$1=$2\n"
}
