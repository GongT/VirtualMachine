#!/usr/bin/env bash

function is_inside_namespace() {
	[[ "$(systemd-detect-virt)" = "systemd-nspawn" ]]
}

function within_machine() {
	if [[ -z "$1" ]]; then
		die "invalid machine name: (empty)"
	fi
	if ! echo "$1" | grep -qiE "^[a-z0-9]+$" ; then
		die "invalid machine name: $1"
	fi
	echo "Using virtual machine: ${TEXT_INFO}${1}${TEXT_RESET}"
	inside_within && die "Control flow error: machine is already set."
	export CURRENT_MACHINE="$1"
}

function end_within() {
	require_within
	if is_inside_namespace ; then
		die "Cannot end_within when run as nspawn process"
	fi
	export CURRENT_MACHINE=""
}

function inside_within() {
	[[ -n "$CURRENT_MACHINE" ]]
}

function require_within() {
	inside_within || die "Control flow error: machine not set."
}

function require_within_exists() {
	machine_path "/etc/system-release" | path_exists || die "Control flow error: current machine not exists."
}

function machine_path() {
	require_within
	realpath --no-symlinks -m "/var/lib/machines/$CURRENT_MACHINE/$1"
}

function path_exists() {
	local F_PATH
	F_PATH="$(cat)"
	[[ -e "$F_PATH" ]]
}

function where_share() {
	require_within
	realpath --no-symlinks -m "/data/AppData/share/$CURRENT_MACHINE/$1"
}

function where_share_from() {
	realpath --no-symlinks -m "/data/AppData/share/$1/$2"
}

function where_log() {
	require_within
	realpath --no-symlinks -m "/data/AppData/logs/$CURRENT_MACHINE/$1"
}

function where_app_data() {
	require_within
	realpath --no-symlinks -m "/data/AppData/data/$CURRENT_MACHINE/$1"
}

function where_config() {
	require_within
	realpath --no-symlinks -m "/data/AppData/config/$CURRENT_MACHINE/$1"
}

function where_socket_from() {
	realpath --no-symlinks -m "/dev/shm/MachinesSockets/$1"
}

function where_socket() {
	require_within
	realpath --no-symlinks -m "/dev/shm/MachinesSockets/$CURRENT_MACHINE/$1"
}

function where_source() {
	realpath --no-symlinks -m "/data/DevelopmentRoot/$1"
}

function where_volume() {
	realpath --no-symlinks -m "/data/Volumes/$1"
}

function where_cache() {
	if inside_within ; then
		require_within
		realpath --no-symlinks -m "/data/Cache/$CURRENT_MACHINE/$1"
	else
		realpath --no-symlinks -m "/data/Cache/$1"
	fi
}

function init_log_file(){
	local TARGET
	if inside_within ; then
		TARGET="$(machine_path "/var/tmp/$1.${RANDOM}.log")"
	else
		TARGET= "/tmp/init-machines/$1.${RANDOM}.log"
	fi
	mkdir -p "$(dirname "$TARGET")"
	echo "$TARGET"
}
