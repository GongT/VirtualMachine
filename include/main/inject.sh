#!/usr/bin/env bash

cd "$( dirname "${BASH_SOURCE[0]}" )"
source ../include.sh

ACTION="$1"

function copy_ssh_keys() {
	echo "$TEXT_MUTED"
	cp -rfv -L ~/.ssh "$(machine_path /root)"
	echo "$TEXT_RESET"
}

require_within
case "$ACTION" in
ssh-keys)
	copy_ssh_keys
;;
*)
	die "Unknown inject action: $ACTION"
esac
