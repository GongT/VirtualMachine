#!/usr/bin/env bash

function chroot_systemctl_enable() {
	require_within
	echo "Enabling service: $*...${TEXT_MUTED}"
	chroot "$(machine_path)" systemctl enable "$@"
	echo -n "${TEXT_RESET}"
}

function chroot_systemctl_disable() {
	require_within
	echo "Disabling service: $*...${TEXT_MUTED}"
	chroot "$(machine_path)" systemctl disable "$@"
	echo -n "${TEXT_RESET}"
}

function copy_service() {
	local TARGET FILE="$1" NAME="$2"
	TARGET="$(machine_path "/usr/lib/systemd/system/$NAME")"

	echo "copy service file: ${TEXT_MUTED}$FILE${TEXT_RESET}"
	cp -L "$FILE" "$TARGET"
}

function copy_service_override() {
	local TARGET FILE="$1" NAME="$2"
	TARGET="$(machine_path "/usr/lib/systemd/system/$NAME.d/override.conf")"

	echo "copy service override file: ${TEXT_MUTED}$FILE${TEXT_RESET}"
	mkdir -p "$(dirname "$TARGET")"
	cp -L "$FILE" "$TARGET"
}
