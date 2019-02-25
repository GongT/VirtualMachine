#!/usr/bin/env bash

function prepare_ssh_client() {
	local TARGET_RSA_FILE

	TARGET_RSA_FILE="$(machine_path "/root/id_rsa")"
	if [[ -e "$TARGET_RSA_FILE" ]]; then
		return
	fi

	local KEY_FILE="/var/lib/machines/id_rsa"
	local PUB_FILE="/var/lib/machines/id_rsa.pub"
	if ! [[ -e "/var/lib/machines/id_rsa" ]]; then
		ssh-keygen -t rsa -f "$KEY_FILE" -N ""
		concat_authorized_keys /root/.ssh/authorized_keys "${PUB_FILE}"
	fi

	cp -fv "${KEY_FILE}" "$TARGET_RSA_FILE"

	run_dnf_server -y install openssh-clients
}

function concat_authorized_keys() {
	local AUTH_KEY_FILE="$1"
	local PUB_KEY_FILE="$2"
	local PUB_CONTENT
	PUB_CONTENT="$(cat "$PUB_KEY_FILE" | awk '{print $1" "$2}')"

	append_if_not "$PUB_CONTENT ### nspawn key from $PUB_KEY_FILE" "$AUTH_KEY_FILE" "$PUB_CONTENT" \
		&& echo "authorized_keys: exists public key in $PUB_KEY_FILE" \
		|| echo "authorized_keys: inserted new key from $PUB_KEY_FILE"
}
