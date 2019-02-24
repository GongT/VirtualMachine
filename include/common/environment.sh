#!/usr/bin/env bash

function is_inside_namespace() {
	[[ "$(systemd-detect-virt)" != "systemd-nspawn" ]]
}

function within_machine() {
	if [[ -z "$1" ]]; then
		die "invalid machine name: (empty)"
	fi
	inside_within && die "Control flow error: machine is already set."
	export CURRENT_MACHINE="$1"
}

function end_within() {
	require_within
	if is_inside_namespace ; then
		die "Cannot end within inside namespace"
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
	[[ -e "$(machine_path "/etc/system-release")" ]] || die "Control flow error: current machine not exists."
}

function current_machine() {
	require_within
	echo "$CURRENT_MACHINE"
}

function machine_path() {
	realpath -m "/var/lib/machines/$(current_machine)/$1"
}

function where_share() {
	realpath -m "/data/AppData/share/$(current_machine)/$1"
}

function where_share_from() {
	realpath -m "/data/AppData/share/$1/$2"
}

function where_log() {
	realpath -m "/data/AppData/logs/$(current_machine)/$1"
}

function where_app_data() {
	realpath -m "/data/AppData/data/$(current_machine)/$1"
}

function where_config() {
	realpath -m "/data/AppData/config/$(current_machine)/$1"
}

function where_socket_from() {
	realpath -m "/dev/shm/MachinesSockets/$1"
}

function where_socket() {
	realpath -m "/dev/shm/MachinesSockets/$(current_machine)/$1"
}

function where_source() {
	realpath -m "/data/DevelopmentRoot/$1"
}

function where_volume() {
	realpath -m "/data/Volumes/$1"
}

function where_cache() {
	if inside_within ; then
		realpath -m "/data/Cache/$(current_machine)/$1"
	else
		realpath -m "/data/Cache/$1"
	fi
}

function init_log_file(){
	if inside_within ; then
		mkdir -p "$(machine_path "/var/tmp")"
		machine_path "/var/tmp/$1.${RANDOM}.log"
	else
		mkdir -p "/tmp/init-machines"
		echo "/tmp/init-machines/$1.${RANDOM}.log"
	fi
}
