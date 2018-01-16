#!/usr/bin/env bash

NETWORK_SUBSYS=yes
HOST_FOLDERS=()

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
	local RO=$3
	
	local LOCAL="${MAP%%:*}"
	local REMOTE="${MAP##*:}"
	
	HOST_FOLDERS+=("${ROOT}/${LOCAL}")
	vm-mkdir "${MACHINE}" "${REMOTE}"
	
	echo -e "[Files]
${TYPE}=${ROOT}/${MAP}\n"
}

function vm-mount-type() {
	case "$1" in
	\[config\])
		echo "/data/AppData/config/${MACHINE}"
	;;
	\[app\])
		echo "/data/AppData/data/${MACHINE}"
	;;
	\[share\])
		echo "/data/AppData/share"
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
