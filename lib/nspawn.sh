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
	
	local DIR=$(vm-file "${MACHINE}")
	local NS_FILE="${DIR%/}"
	
	mkdir -p "${DIR}" || die "Can not create dir $DIR"
	screen-run mdnf "${MACHINE}" install systemd || die "dnf install systemd failed"
	
	unlink "$(vm-file "${MACHINE}" .binddir)" &>/dev/null || true
	
	echo "[Exec]
WorkingDirectory=/root
Boot=yes
Environment=

$(${CALLBACK})" >"${NS_FILE}.nspawn.tmp" && \
		cat "${NS_FILE}.nspawn.tmp" >"${NS_FILE}.nspawn" && \
		rm -f "${NS_FILE}.nspawn.tmp" || die "can not create .nspawn file"
		
	if [ "${NETWORK_SUBSYS}" == "yes" ]; then
		vm-systemctl "${MACHINE}" enable systemd-networkd systemd-resolved || die "can not chroot run systemctl"
	fi
	unset MACHINE
}

function vm-command-exits() {
	local DIR=$(vm-file "${1}")
	local CMD=$2
	
	chroot "${DIR}" command -v "${CMD}" &>/dev/null
}

function vm-mkdir() {
	local DIR=$(vm-file "${1}")
	shift
	chroot "${DIR}" mkdir -p "$@" || die "vm mkdir failed: $*"
}

function vm-systemctl() {
	local DIR=$(vm-file "${1}")
	shift
	
	chroot "${DIR}" systemctl "$@" || die "vm systemctl failed: $*"
}

function vm-script() {
	local DIR=$(vm-file "${1}")
	local FILE="$2"
	shift
	shift
	
	cp "$(staff-file "$FILE")" "${DIR}/tmp/$FILE"
	
	chroot "${DIR}" bash "/tmp/$FILE" "$@" || die "chrrot script failed: ${DIR}/tmp/$FILE"
	local RET=$?
	
	unlink "${DIR}/tmp/$FILE"
	
	return ${RET}
}

function host-script() {
	local VM_DIR=$(vm-file "${1}")
	local FILE="$(staff-file "$2")"
	shift
	shift
	
	pushd "${VM_DIR}" &>/dev/null || die "invalid machine dir: ${VM_DIR}"
	bash "${FILE}" "$@"
	local RET=$?
	popd &>/dev/null
	
	return ${RET}
}

function vm-copy() {
	local TARGET=$(vm-file "${1}" "${3}")
	local FILE="$(staff-file "$2")"
	
	cp -r "${FILE}" "${TARGET}"
}
