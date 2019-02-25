#!/usr/bin/env bash

cd "$( dirname "${BASH_SOURCE[0]}" )"
source ../include.sh

function append() {
	echo "${TEXT_MUTED}          $*${TEXT_RESET}" >&2
	echo "$@" >> "$NSPAWN"
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
	data) FROM=$(where_app_data "$HOST") ;;
	source) FROM=$(where_source "$HOST") ;;
	volume) FROM=$(where_volume "$HOST") ;;
	*)
		die "Unknown filesystem type $TYPE"
	esac

	if ! [[ -d "$FROM" ]]; then
		echo "${TEXT_MUTED}making directory $FROM...${TEXT_RESET}"
		mkdir -p "$FROM"
	fi
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


NSPAWN="$(machine_path /).nspawn"
echo "[Exec]
WorkingDirectory=/root
Boot=yes
Environment=
Environment=LANG=en_US.UTF-8
Environment=DISPLAY=:0
NotifyReady=yes
" > "$NSPAWN"

echo "      * environments"
foreach_object ".environments" generate_environments

echo "      * network"
generate_network

echo "      * mount file system"
append "[Files]"
foreach_array ".mount" generate_mounts

if [[ "$(query_json ".bind.log | length")" -ne 0 ]]; then
	append "Bind=$(where_log):/mnt/log"
fi
if [[ "$(query_json ".bind.config | length")" -ne 0 ]]; then
	append "BindReadOnly=$(where_config):/mnt/config"
fi
if [[ "$(query_json ".socket | length")" -ne 0 ]] ; then
	append "Bind=$(where_socket):/mnt/socket"
fi

echo >> "$NSPAWN"
