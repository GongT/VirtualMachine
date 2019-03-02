#!/usr/bin/env bash

cd "$( dirname "${BASH_SOURCE[0]}" )"
source ../include.sh

function init_service() {
	local VAL="$1" NAME="$2" ENABLED=() ENABLED_TYPE TEMPLATE OVERWRITE

	TEMPLATE="$(echo "$VAL" | query_json_value '.template')"
	OVERWRITE="$(echo "$VAL" | query_json_value '.overwrite')"

	if ! echo "$NAME" | grep -q -- '\.' ; then
		NAME="$NAME.service"
	fi

	if ! is_null_or_empty "$TEMPLATE" ; then
		copy_service "$(where_host "$TEMPLATE")" "$NAME"
	fi

	if ! is_null_or_empty "$OVERWRITE" ; then
		copy_service_override "$(where_host "$OVERWRITE")" "$NAME"
	fi

	ENABLED_TYPE="$(echo "$VAL" | query_json_value '.enabled | type')"
	case "$ENABLED_TYPE" in
	boolean)
		if echo "$VAL" | query_json_condition '.enabled' ; then
			chroot_systemctl_enable "$NAME"
		else
			chroot_systemctl_disable "$NAME"
		fi
	;;
	array)
		if ! echo "$NAME" | grep -q -- '@' ; then
			die "Service file is not generic, cannot enable with array."
		fi
		local PRE="${NAME%%@*}" POS="${NAME##*@}" LIST
		LIST=$(echo "$VAL" | query_json_value '.enabled[]' | xargs -IF bash -c "echo '${PRE}@F${POS}'")
		chroot_systemctl_enable ${LIST}
	;;
	*)
		die "Unknown service enabled type: $VAL ($ENABLED_TYPE)"
	esac
}

require_within

foreach_object '.service' init_service

INIT_SCRIPT=$(query_json '.postscript')
if ! is_null_or_empty "$INIT_SCRIPT" ; then
	echo "Copy first-boot script into machine..."
	SCRIPT="/opt/scripts/$(basename "$INIT_SCRIPT")"
	mkdir -p "$(dirname "$(machine_path "$SCRIPT")")"
	cp -v "$(where_host "$INIT_SCRIPT")" "$(machine_path "$SCRIPT")"

	TMP_FILE="/tmp/created-init-script-${RANDOM}.service"
	echo "
[Unit]
Before=multi-user.target network.target
ConditionFileNotEmpty=!/var/first-boot.lock
OnFailure=poweroff.target
OnFailureJobMode=replace-irreversibly

[Service]
EnvironmentFile=/etc/environment
Type=oneshot
RemainAfterExit=true
ExecStart=/bin/bash --login \"$SCRIPT\"
ExecStartPost=/bin/bash -c 'echo yes > /var/first-boot.lock'
StandardError=journal+console
StandardOutput=journal+console
TimeoutStartSec=10m

[Install]
WantedBy=multi-user.target
" > "$TMP_FILE"

	copy_service "$TMP_FILE" "first-boot.service"
	chroot_systemctl_enable "first-boot.service"
fi
