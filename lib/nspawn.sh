#!/usr/bin/env bash

pushd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" &>/dev/null
source "../CONFIG"
source "mdnf.sh"
source "vm-config.sh"
popd &>/dev/null

if [ -z "${LIB_MACHINE}" ] || [ ! -e "${LIB_MACHINE}" ]; then
	die "machine root not exists."
fi

function prepare-vm() {
	export MACHINE=$1
	shift
	local CALLBACK=$1
	
	local DIR="${LIB_MACHINE}/${MACHINE}"
	mkdir -p "${DIR}" || die "Can not create dir $DIR"
	mdnf "${MACHINE}" install systemd || die "dnf install systemd failed"
	
	echo "[Exec]
WorkingDirectory=/root
Boot=yes
Environment=

$(${CALLBACK})" >"${DIR}.nspawn.tmp" && \
		cat "${DIR}.nspawn.tmp" >"${DIR}.nspawn" && \
		rm -f "${DIR}.nspawn.tmp" || die "can not create .nspawn file"
	
	if [ "${NETWORK_SUBSYS}" == "yes" ]; then
		vm-systemctl "${MACHINE}" enable systemd-networkd systemd-resolved || die "can not chroot run systemctl"
	fi
	unset MACHINE
}

function vm-command-exits() {
	local NAME=$1
	local CMD=$2
	local DIR="${LIB_MACHINE}/${NAME}"
	
	chroot "${DIR}" command -v "${CMD}" &>/dev/null
}

function vm-mkdir() {
	local NAME=$1
	shift
	local DIR="${LIB_MACHINE}/${NAME}"
	chroot "${DIR}" mkdir -p "$@"
}

function vm-systemctl() {
	local NAME=$1
	shift
	local DIR="${LIB_MACHINE}/${NAME}"
	
	chroot "${DIR}" systemctl "$@"
}

function vm-script() {
	local NAME=$1
	local FILE=$2
	local DIR="${LIB_MACHINE}/${NAME}"
	
	cp "${FILE}" "${DIR}/tmp/${FILE}"
	
	chroot "${DIR}" bash "/tmp/${FILE}"
	local RET=$?
	
	unlink "${DIR}/tmp/${FILE}"
	
	return ${RET}
}
