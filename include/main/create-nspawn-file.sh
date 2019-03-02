#!/usr/bin/env bash

cd "$( dirname "${BASH_SOURCE[0]}" )"
source ../include.sh

function append() {
	# echo "${TEXT_MUTED}          $*${TEXT_RESET}" >&2
	echo "$@" >> "$NSPAWN"
}

function generate_mounts() {
	local INDEX="$2" VALUE="$1" TYPE HOST DESTINATION LINE

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

	if echo "$VALUE" | query_json_condition '.options | contains(["readonly"])' ; then
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
	cache) FROM=$(where_source "$HOST") ;;
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
		append "VirtualEthernetExtra=vm-$CURRENT_MACHINE:hostonly"
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

require_within

NSPAWN="$(machine_path /).nspawn"
echo "[Exec]
WorkingDirectory=/root
Boot=yes
Environment=
Environment=LANG=en_US.UTF-8
Environment=DISPLAY=:0
NotifyReady=yes
" > "$NSPAWN"

echo "      * network"
generate_network

echo "      * mount file system"
append "[Files]"
foreach_array ".mount" generate_mounts

if [[ "$(query_json ".bind.log | length")" -ne 0 ]]; then
	mkdir -p "$(where_log)"
	append "Bind=$(where_log):/mnt/log"
fi
if [[ "$(query_json ".bind.config | length")" -ne 0 ]]; then
	mkdir -p "$(where_config)"
	if [[ "$(query_json ".bind.configWritable")" = "true" ]] ; then
		append "Bind=$(where_config):/mnt/config"
	else
		append "BindReadOnly=$(where_config):/mnt/config"
	fi
fi
if [[ "$(query_json ".bind.socket | length")" -ne 0 ]] ; then
	append "Bind=$(where_socket):/run/socket"
fi
if [[ "$(query_json ".bind.cache | length")" -ne 0 ]]; then
	append "Bind=$(where_cache):/mnt/cache"
fi

echo >> "$NSPAWN"
