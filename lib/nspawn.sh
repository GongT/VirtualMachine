#!/usr/bin/env bash

pushd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" &>/dev/null
LIBRARY_PATH="$(pwd)"
source "../CONFIG"
source "../PASSWORDS"
source "mdnf.sh"
source "vm-config.sh"
popd &>/dev/null

if [ -z "${LIB_MACHINE}" ] || [ ! -e "${LIB_MACHINE}" ]; then
	die "machine root '${LIB_MACHINE}' not exists."
fi

export MACHINE="......" # just invalid thing

function add-systemd-journal-clean() {
	local TARGET="$(vm-file "${MACHINE}" /usr/lib/systemd/system)"
	cp -r "${LIBRARY_PATH}/service/." "${TARGET}"
	# echo cp -r "${LIBRARY_PATH}/service/." "${TARGET}"
}

function prepare-vm() {
	export MACHINE=$1
	shift
	local CALLBACK=$1
	
	local DIR=$(vm-file "${MACHINE}")
	local NS_FILE="${DIR%/}"
	
	mkdir -p "${DIR}" || die "Can not create dir $DIR"
	
	screen-run mdnf "${MACHINE}" install systemd bash openssh-clients || die "dnf install systemd bash failed"
	
	cat "$(vm-file "${MACHINE}" .binddir)" | xargs --no-run-if-empty mkdir -vp
	unlink "$(vm-file "${MACHINE}" .binddir)" &>/dev/null || true
	
	add-mdnf
	
	echo "[Exec]
WorkingDirectory=/root
Boot=yes
Environment=

$(${CALLBACK})" >"${NS_FILE}.nspawn.tmp" && \
		cat "${NS_FILE}.nspawn.tmp" >"${NS_FILE}.nspawn" && \
		rm -f "${NS_FILE}.nspawn.tmp" || die "can not create .nspawn file"
	
	chmod a-x "${NS_FILE}.nspawn"
		
	if [ "${NETWORK_SUBSYS}" == "yes" ]; then
		vm-systemctl "${MACHINE}" enable systemd-networkd systemd-resolved || die "can not chroot run systemctl"
		local RESOLV_FILE="${DIR}/etc/resolv.conf"
		if [ ! -h "${RESOLV_FILE}" ] && [ ! -e "${RESOLV_FILE}" ]; then
			ln -s ../var/run/systemd/resolve/resolv.conf "${RESOLV_FILE}"
		fi
	fi
	
	add-systemd-journal-clean
	vm-systemctl "${MACHINE}" enable journal-clean.timer
}

function vm-command-exits() {
	local DIR=$(vm-file "${1}")
	local CMD=$2
	
	chroot "${DIR}" command -v "${CMD}" &>/dev/null
}

function vm-file-exits() {
	local P=$(vm-file "${1}")
	[ -e "$P" ]
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

function vm-run() {
	local CMD=$1
	shift
	echo VM-RUN: $CMD >&2
	
	# CMD="echo \"arguments: \$@\" >&2; $CMD"
	if ! machinectl status -q "$MACHINE" &>/dev/null ; then
		echo "creating container: $MACHINE..." >&2
		_stop-temp-machine
		systemd-run --unit="$(_temp-machine)" --service-type=simple systemd-nspawn --boot --settings=trusted -M "$MACHINE"
		sleep 2
	fi
	echo "attaching to container: $MACHINE..." >&2
	machinectl shell "$MACHINE" /bin/bash -c "$CMD" -- "$@"
	
	_stop-temp-machine
}

function _stop-temp-machine() {
	local TMP_MACHINE="$(_temp-machine)"
	if service --status-all | grep -Fq "${TMP_MACHINE}" ; then
		systemctl stop "${TMP_MACHINE}" || true
		systemctl reset-failed "${TMP_MACHINE}" || true
	fi
}

function _temp-machine() {
	echo "${MACHINE}.install-machine"
}

function vm-script() {
	local VM="$1"
	local DIR=$(vm-file "$VM" "/mnt/install")
	local FILE="$2"
	shift
	shift
	
	RUN_BASE=$(basename "$FILE")
	
	mkdir -p "${DIR}"
	cat "$(staff-file "$FILE")" > "${DIR}/${RUN_BASE}" || die "no file: $(staff-file "$FILE")"
	cat "${LIBRARY_PATH}/_lib.sh" > "${DIR}/_lib.sh"
	
	local I=0
	local i=""
	
	for i in "$@"; do
		echo -n "$i" | sed -e "s/\r//" > "${DIR}/ARG${I}.sh"
		ARGLIST+="\"\$(</mnt/install/ARG${I}.sh)\" "
		I=$((I + 1))
	done
	
	echo "#!/bin/bash

if [ -e '/mnt/install/${RUN_BASE}' ]; then
	source /mnt/install/_lib.sh
	source '/mnt/install/${RUN_BASE}' ${ARGLIST}
else
	echo 'no such file: /mnt/install/${RUN_BASE} in VM{${VM}}
 from: $(staff-file "$FILE")
 to:   ${DIR}/${RUN_BASE}' >&2
	ls -lh --color /mnt/install
	exit 1
fi
" > "${DIR}/_entry.sh"
	chmod a+x "${DIR}/_entry.sh"
	
	echo "run in vm: $(staff-file "$FILE")" >&2
	echo "run in vm: ${DIR}/${RUN_BASE}" >&2
	MACHINE="$VM" vm-run "/mnt/install/_entry.sh" "$@" || die "vm run script failed"
	
	local RET=$?
	
	# unlink "${DIR}/${RUN_BASE}"
	
	return ${RET}
}

function host-script() {
	local VM_DIR=$(vm-file "${1}")
	local FILE="$(staff-file "$2")"
	shift
	shift
	
	# echo "host-script: $FILE $*"
	
	pushd "${VM_DIR}" &>/dev/null || die "invalid machine dir: ${VM_DIR}"
	bash -c "echo \"arguments: \$*\" >&2; source '${LIBRARY_PATH}/_lib.sh'; source ${FILE} \"\$@\"" -- "$@"
	local RET=$?
	popd &>/dev/null
	
	return ${RET}
}

function vm-copy() {
	local TARGET="$(vm-file "${1}" "${3}")"
	local FILE="$(staff-file "$2")"
	
	cp -r "${FILE}" "${TARGET}"
}
