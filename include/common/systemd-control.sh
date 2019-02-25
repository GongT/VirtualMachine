#!/usr/bin/env bash

function machine_systemctl() {
	require_within
	systemctl status -M "$CURRENT_MACHINE" "$@"
}

function copy_service() {
	local TARGET
	TARGET="$(machine_path /usr/lib/systemd/system)"

	echo "copy service file: $(basename "$1")"
	cp "$1" "$TARGET"
}
