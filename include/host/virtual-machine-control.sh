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
	echo "Booting up machine: $CURRENT_MACHINE..." >&2
	set_machine_service_timeout 10m
	systemctl --quiet start "$CURRENT_MACHINE.machine.service" || {
		systemctl stop "$CURRENT_MACHINE.machine.service"
		die "Failed to boot machine."
	}
	sleep 3
	if ! is_running ; then
		systemctl stop "$CURRENT_MACHINE.machine.service"
		die "Failed to boot machine."
	fi
	unset_machine_service_timeout
}

function shutdown() {
	if ! is_running ; then
		systemctl stop "$CURRENT_MACHINE.machine.service" &>/dev/null || true
		systemctl reset-failed "$CURRENT_MACHINE.machine.service" &>/dev/null || true
		echo "Shutting down machine - already stopped..." >&2
		return
	fi

	echo "Shutting down machine..." >&2
	systemctl --quiet stop "$CURRENT_MACHINE.machine.service" || die "Failed to shutdown machine."
	sleep 3
	if is_running ; then
		die "Failed to shutdown machine."
	fi
}

function is_running() {
	require_within
	machinectl status "$CURRENT_MACHINE" &>/dev/null
}

function set_machine_service_timeout() {
	local SERVICE_FILE_OVERRIDE="/usr/lib/systemd/system/${CURRENT_MACHINE}.machine.service.d/timeout.conf"
	mkdir -p "$(dirname "$SERVICE_FILE_OVERRIDE")"
	echo "[Service]
TimeoutStartSec=$1

" > "$SERVICE_FILE_OVERRIDE"
	systemctl daemon-reload
}

function unset_machine_service_timeout() {
	local SERVICE_FILE_OVERRIDE="/usr/lib/systemd/system/${CURRENT_MACHINE}.machine.service.d/timeout.conf"
	rm -f "$SERVICE_FILE_OVERRIDE"
	systemctl daemon-reload
}

function create_machine_service() {
	require_within

	local SERVICE_FILE="/usr/lib/systemd/system/${CURRENT_MACHINE}.machine.service"

	echo "Write machine service into: ${TEXT_MUTED}$SERVICE_FILE${TEXT_RESET}"

	echo "[Unit]" > "$SERVICE_FILE"
	function append() {
		echo "$*" >> "$SERVICE_FILE"
	}

	append "Description=systemd.nspawn container - $CURRENT_MACHINE"
	append "Documentation=man:systemd-nspawn(1)"
	append "PartOf=machines.target"
	append "Before=machines.target"
	append "Requires=$(echo $(query_json '.unit.dependency[]'))"
	append "After=$(echo $(query_json '.unit.dependency[]'))"
	append "After=network.target systemd-resolved.service systemd-networkd.service"
	append "RequiresMountsFor=/var/lib/machines"
	append "RequiresMountsFor=/data/Cache"
	append "RequiresMountsFor=/data/AppData"

	function requires_device() {
		local DEVICE_SERVICE_FILE="$(systemctl list-units --all '*.device' | grep -- "$1" | awk '{print $1}')"
		if [[ -n "$DEVICE_SERVICE_FILE" ]]; then
			append "Requires=$DEVICE_SERVICE_FILE"
			append "After=$DEVICE_SERVICE_FILE"
		fi
	}
	if [[ "$(query_json ".specialConfig.dynamicBlockDevice | length")" -ne 0 ]]; then
		foreach_array ".specialConfig.dynamicBlockDevice" requires_device
	fi

	append "[Install]"
	append "WantedBy=machines.target"

	append "[Service]"
	append "Environment=MACHINE=\"$CURRENT_MACHINE\""
	append "ExecStartPre=/usr/bin/mkdir -p /dev/shm/MachinesSockets"
	append "ExecStartPre=/usr/bin/chmod 0777 /dev/shm/MachinesSockets"

	function find_right_device() {
		append "ExecStartPre=/bin/bash /var/lib/machines/find-mount.sh $1 "
	}
	if [[ "$(query_json ".specialConfig.dynamicBlockDevice | length")" -ne 0 ]]; then
		cp -f "$SCRIPT_INCLUDE_ROOT/special/find-mount.sh" "/var/lib/machines/find-mount.sh"
		foreach_array ".specialConfig.dynamicBlockDevice" find_right_device
	fi

	append "ExecStartPre=-/usr/bin/machinectl terminate \$MACHINE"
	append "ExecStart=/usr/bin/systemd-nspawn --settings=trusted --machine \$MACHINE"
	append "ExecReload=/usr/bin/systemctl --machine \$MACHINE restart dnsmasq"
	append "ExecStop=/usr/bin/systemctl --machine \$MACHINE poweroff"
	append "KillSignal=SIGINT"
	append "KillMode=mixed"
	append "Type=notify"
	append "Slice=machine.slice"
	append "Delegate=yes"
	append "Restart=on-failure"

	append "LimitNOFILE=infinity"
	append "LimitMEMLOCK=infinity"
	append "OOMScoreAdjust=-1000"

	append "TimeoutStopSec=60s"
	append "RestartSec=10s"




	systemctl daemon-reload
}