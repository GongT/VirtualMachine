#!/usr/bin/env bash

function init_machine_base() {
	local MACHINE_TO_INSTALL="$1"

	if ! echo "$MACHINE_TO_INSTALL" | grep -qiE '^[a-z0-9]+$' ; then
		die "Invalid virtual machine name: $MACHINE_TO_INSTALL"
	fi

	echo -e "Initialize virtual machine ${TEXT_INFO}$MACHINE_TO_INSTALL${TEXT_RESET} with script:\n    ${TEXT_MUTED}$2${TEXT_RESET}"

	title_stack_push "Initializing machine $MACHINE_TO_INSTALL..."
	within_machine "$MACHINE_TO_INSTALL"
	shutdown

	create_machine_json "$2"

	echo "Initializing base system..."
	local TESTING_PATH
	TESTING_PATH="$(machine_path /bin/bash)"
	if [[ -e "$TESTING_PATH" ]] ; then
		echo "  - Already exists"
	else
		echo "  - Base environment missing, installing..."
		run_dnf install systemd bash
	fi

	echo "Configuring..."
	local RESOLVE
	RESOLVE="$(machine_path /etc/resolv.conf)"
	[[ -e "$RESOLVE" ]] || [[ -L "$RESOLVE" ]] && unlink "$RESOLVE"
	ln -s /var/run/systemd/resolve/resolv.conf "$RESOLVE"
	echo "  - /etc/resolv.conf"

	query_json '.hostname' > "$(machine_path /etc/hostname)"
	echo "  - /etc/hostname"

	local NSPAWN
	NSPAWN="$(machine_path /).nspawn"
	echo "[Exec]
WorkingDirectory=/root
Boot=yes
Environment=
Environment=LANG=en_US.UTF-8
Environment=DISPLAY=:0
NotifyReady=yes
" > "$NSPAWN"

	local append
	append() {
		echo "${TEXT_MUTED}          $*${TEXT_RESET}" >&2
		echo "$@" >> "$NSPAWN"
	}

	echo "      * environments"
	foreach_object ".environments" generate_environments

	echo "      * network"
	generate_network

	echo "      * mount file system"
	append "[Files]"
	foreach_array ".mount" generate_mounts

	echo "  - ${NSPAWN}"
	unset append
	echo >> "$NSPAWN"

	end_within
}

function generate_environments() {
	append "Environment=$1=$(cat)"
}

function generate_mounts() {
	local INDEX="$1"
	local VALUE TYPE HOST DESTINATION LINE
	VALUE="$(cat)"

	HOST="$(echo "$VALUE" | query_json_value ".host")"
	if is_null_or_empty "$HOST" ; then
		die "Value of mount source is not set (${INDEX}):\n${VALUE}"
	fi

	DESTINATION="$(echo "$VALUE" | query_json_value ".destination")"
	if is_null_or_empty "$DESTINATION"; then
		DESTINATION="$HOST"
	fi

	if [[ -z "$DESTINATION" ]]; then
		die "Value of mount destination is not set (${INDEX}):\n${VALUE}"
	fi

	TYPE="$(echo "$VALUE" | query_json_value ".type")"
	if [[ "$TYPE" = "tmpfs" ]]; then
		append "TemporaryFileSystem=${DESTINATION}"
		return
	fi

	if echo "$VALUE" | query_json_condition '.options | contains(["readonly"])' >/dev/null ; then
		LINE="BindReadOnly="
	else
		LINE="Bind="
	fi

	local FROM
	case "$TYPE" in
	root) FROM=$(realpath --no-symlinks -m "$HOST") ;;
	share) FROM=$(where_share "$HOST") ;;
	log) FROM=$(where_log "$HOST") ;;
	data) FROM=$(where_app_data "$HOST") ;;
	config) FROM=$(where_config "$HOST") ;;
	socket) FROM=$(where_socket "$HOST") ;;
	source) FROM=$(where_source "$HOST") ;;
	volume) FROM=$(where_volume "$HOST") ;;
	*)
		die "Unknown filesystem type $TYPE"
	esac
	append "${LINE}${FROM}:${DESTINATION}"
}

function generate_network() {
	append "[Network]"
	local NETWORK_TYPE
	NETWORK_TYPE=$(query_json '.network.type')
	case "$NETWORK_TYPE" in
	disable)
		append "Private=yes"
		append "VirtualEthernet=no"
	;;
	hostonly)
		append "Private=yes"
		append "VirtualEthernet=yes"
		append "VirtualEthernetExtra=vm-$MACHINE_TO_INSTALL:hostonly"
		append "Zone=hostonly"
	;;
	bridge)
		local BR_NAME
		BR_NAME=$(query_json '.network.br')
		if is_null_or_empty "$BR_NAME" ; then
			BR_NAME="bridge0"
		fi
		append "Private=yes"
		append "Bridge=$BR_NAME"
	;;
	*)
		die "Unknown networking type: $NETWORK_TYPE"
	esac
}
