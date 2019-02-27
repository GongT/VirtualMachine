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
	set_machine_service_timeout 60s
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
function create_machine_service() {
	require_within

	local SERVICE_FILE="/usr/lib/systemd/system/${CURRENT_MACHINE}.machine.service"

	echo "Write machine service into: ${TEXT_MUTED}$SERVICE_FILE${TEXT_RESET}"
	echo "[Unit]
Description=systemd.nspawn container - $CURRENT_MACHINE
Documentation=man:systemd-nspawn(1)
PartOf=machines.target
Before=machines.target
After=network.target systemd-resolved.service systemd-networkd.service
RequiresMountsFor=/var/lib/machines
RequiresMountsFor=/data/Cache
RequiresMountsFor=/data/AppData

[Install]
WantedBy=machines.target

[Service]
Environment=MACHINE=\"$CURRENT_MACHINE\"
ExecStartPre=-/usr/bin/machinectl terminate \$MACHINE
ExecStart=/usr/bin/systemd-nspawn --settings=trusted --machine \$MACHINE
ExecReload=/usr/bin/systemctl --machine \$MACHINE restart dnsmasq
ExecStop=/usr/bin/systemctl --machine \$MACHINE poweroff
KillSignal=SIGINT
KillMode=mixed
Type=notify
Slice=machine.slice
Delegate=yes
Restart=on-failure

LimitNOFILE=infinity
LimitMEMLOCK=infinity
OOMScoreAdjust=-1000

TimeoutStopSec=60s
RestartSec=10s
" > "$SERVICE_FILE"
	systemctl daemon-reload
}