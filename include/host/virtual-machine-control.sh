#!/usr/bin/env bash

function ensure_booted() {
	require_within
	if is_running ; then
		echo "Booting up machine - already running..." >&2
		return
	fi

	boot
}

function boot() {
	echo "Booting up machine..." >&2
	systemctl --wait --quiet start "$CURRENT_MACHINE.machine.service"
	sleep 3
	if ! is_running ; then
		die "Failed to boot machine."
	fi
}

function shutdown() {
	if ! is_running ; then
		echo "Shutting down machine - already stopped..." >&2
		return
	fi

	echo "Shutting down machine..." >&2
	systemctl --wait --quiet stop "$CURRENT_MACHINE.machine.service"
	sleep 3
	if is_running ; then
		die "Failed to shutdown machine."
	fi
}

function is_running() {
	require_within
	machinectl status "$CURRENT_MACHINE" &>/dev/null
}
