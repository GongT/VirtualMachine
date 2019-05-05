#!/usr/bin/env bash

cd "$( dirname "${BASH_SOURCE[0]}" )"
source ../include.sh

ACTION="$1"

function copy_ssh_keys() {
	echo "$TEXT_MUTED"
	cp -rfv -L ~/.ssh "$(machine_path /root)"
	echo "$TEXT_RESET"
}

function init_dnf_client() {
	if ! [[ -e "$(machine_path /usr/bin/dnf)" ]]; then
		run_dnf install dnf
	fi

	local NSPAWN="$(machine_path /).nspawn"

	echo "[Files]
BindReadOnly=/etc/yum.repos.d.custom:/etc/yum.repos.d" >> "$NSPAWN"
}

require_within
case "$ACTION" in
ssh-keys)
	copy_ssh_keys
;;
dnf)
	init_dnf_client
;;
*)
	die "Unknown inject action: $ACTION"
esac
