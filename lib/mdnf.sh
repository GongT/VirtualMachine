#!/usr/bin/env bash

if [ -z "${LIB_MACHINE}" ]; then
	export LIB_MACHINE=/var/lib/machines
fi

function mdnf() {
	local MACHINE="${LIB_MACHINE}/$1"
	if [ ! -d "$MACHINE" ]; then
			echo "No such machine: $MACHINE" >&2
			exit 1
	fi
	shift
	
	/usr/bin/dnf -y \
		   --setopt=cachedir=../../../../../../../../../../../../../../../var/cache/dnf \
		   --setopt=config_file_path=/etc/dnf/dnf.conf \
		   --setopt=reposdir=/etc/yum.repos.d \
		   --releasever=/ --installroot="${MACHINE}" "$@"
}

LIB_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

function add-mdnf() {
	if [ ! -e "${LIB_DIR}/remote-key.rsa" ]; then
		echo | ssh-keygen -f "${LIB_DIR}/remote-key.rsa"
		mkdir -p ~/.ssh
		touch ~/.ssh/authorized_keys
		chmod 0600 ~/.ssh/authorized_keys
	fi
	local PUB_KEY=$(cat "${LIB_DIR}/remote-key.rsa.pub" | awk '{print $1" "$2}')
	if ! grep "${PUB_KEY}" ~/.ssh/authorized_keys -q &>/dev/null ; then
		echo >> ~/.ssh/authorized_keys
		echo "${PUB_KEY}" | awk '{print $1" "$2" # machine key"}' >> ~/.ssh/authorized_keys
		echo >> ~/.ssh/authorized_keys
	fi

	local MDNF_BIN="$(vm-file "${MACHINE}" /usr/local/bin/mdnf)"
	echo "#!/bin/bash
ssh server /usr/local/bin/mdnf \"${MACHINE}\" \"\$@\"
" > "${MDNF_BIN}"
	chmod 0555 "${MDNF_BIN}"
	
	local RSA_FILE="$(vm-file "${MACHINE}" /root/.ssh/id_rsa)"
	if [ ! -e "${RSA_FILE}" ]; then
		mkdir -p "$(dirname "${RSA_FILE}")"
		cat "${LIB_DIR}/remote-key.rsa" > "${RSA_FILE}"
		chmod 0600 "${RSA_FILE}"
	fi
}

function add-sshd() {
	local CFG_FILE="$(vm-file "${MACHINE}" /etc/ssh/sshd_config)"
	if [ ! -e "${CFG_FILE}" ]; then
		mkdir -p "$(dirname "${CFG_FILE}")"
		cat "${LIB_DIR}/config/sshd_config" > "${CFG_FILE}"
		chmod 0600 "${CFG_FILE}"
	fi
	local PUB_KEY=$(cat "${LIB_DIR}/remote-key.rsa.pub" | awk '{print $1" "$2}')
	
	local AUTH_FILE="$(vm-file "${MACHINE}" /root/.ssh/authorized_keys)"
	if [ ! -e "${AUTH_FILE}" ]; then
		mkdir -p "$(dirname "${AUTH_FILE}")"
		cat "${LIB_DIR}/remote-key.rsa.pub" | awk '{print $1" "$2}' > "${AUTH_FILE}"
		chmod 0600 "${AUTH_FILE}"
	fi
	if ! vm-command-exits "${MACHINE}" /usr/sbin/sshd ; then
		mdnf "${MACHINE}" install openssh-server
	fi
	vm-systemctl "${MACHINE}" enable sshd
}