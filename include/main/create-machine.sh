#!/usr/bin/env bash

cd "$( dirname "${BASH_SOURCE[0]}" )"
source ../include.sh

require_within
echo -e "Initialize virtual machine ${TEXT_INFO}$CURRENT_MACHINE${TEXT_RESET} with script:\n    ${TEXT_MUTED}$MACHINE_DEFINE_FILE${TEXT_RESET}"

### init variables (json) ###
create_machine_json "$MACHINE_DEFINE_FILE"
shutdown

### base system ###
echo "Initializing base system..."
TESTING_PATH="$(machine_path /bin/bash)"
if [[ -e "$TESTING_PATH" ]] ; then
	echo "  - Already exists"
else
	echo "  - Base environment missing, installing..."
	run_dnf install systemd bash fedora-release
	chroot_systemctl_enable systemd-networkd systemd-resolved
fi

### system configure ###
echo "Configuring..."
RESOLVE="$(machine_path /etc/resolv.conf)"
[[ -e "$RESOLVE" ]] || [[ -L "$RESOLVE" ]] && unlink "$RESOLVE"
ln -s /var/run/systemd/resolve/resolv.conf "$RESOLVE"
echo "  - /etc/resolv.conf"

query_json '.hostname' > "$(machine_path /etc/hostname)"
echo "  - /etc/hostname"

### create .nspawn file ###
source_main create-nspawn-file.sh "$CURRENT_MACHINE"
echo "  - Created nspawn file."

### dnf install packages ###
install_package \
	"$(query_json ".install.packages[]")" \
	"$(query_json ".install.packagesFile")"
echo "  - Required packages installed."

### inject custom tool like dnf ###
function call_inject_script() {
	local WHAT="$1"
	run_main "inject.sh" "$WHAT"
	echo "  - inject tool: $WHAT"
}
foreach_array '.install.inject' call_inject_script

### copy files from current dir to remote ###
function call_copy_files() {
	local FROM="$2" TARGET="$1" FROM_ABS TARGET_ABS COUNT
	echo "Copy '${FROM}' to '${TARGET}'..."
	FROM_ABS=$(where_host "$FROM")
	TARGET_ABS=$(machine_path "$TARGET")
	echo -n "${TEXT_MUTED}" >&2
	mkdir -p "$(dirname "$TARGET_ABS")"
	COUNT=$(cp -vr -- "$FROM_ABS" "$TARGET_ABS" | wc -l)
	echo -n "${TEXT_RESET}" >&2
	echo "  ${COUNT} files copied."
}
foreach_object '.install.copyFiles' call_copy_files

### copy init config files to AppData ###
INIT_CONFIG_PATH="$(query_json ".bind.initConfig")"
if ! is_null_or_empty "$INIT_CONFIG_PATH" ; then
	CONFIG_STORE="$(where_config)"
	mkdir -p "$CONFIG_STORE"
	# -n / --no-clobber: no overwrite
	cp --no-clobber -rf "$(where_host "${INIT_CONFIG_PATH}")/." "$CONFIG_STORE"
fi

### create symlink from /etc or /var/log or ... to /mnt/xxx
function create_bind_link() {
	local FROM="$5" TO="$6" VALUE="$1" LINK TARGET
	LINK="$(machine_path "${TO}/${VALUE}")"
	TARGET="$(realpath --no-symlinks -m "${FROM}/${VALUE}")"
	if [[ -L "$LINK" ]] ; then
		unlink "$LINK"
	fi
	if [[ -e "$LINK" ]] ; then
		rm -rf "$LINK"
	fi
	echo "create link: $LINK, point to: $TARGET."
	mkdir -p "$(dirname "$LINK")"
	ln -s "$TARGET" "$LINK"
}

function run_them() {
	foreach_array ".bind.config" create_bind_link "/mnt/config" "/etc"
	foreach_array ".bind.log" create_bind_link "/mnt/log" "/var/log"
	foreach_array ".bind.cache" create_bind_link "/mnt/cache" "/var/cache"
}
screen_run "Create links" run_them

### create profile ###
PROFILE="$(machine_path /etc/profile.d/environment.sh)"
ENVFILE="$(machine_path /etc/environment)"
OLD_ENV=$([[ -e "$ENVFILE" ]] && cat "$ENVFILE")
echo "" > "$PROFILE"
echo "" > "$ENVFILE"
function generate_environments() {
	local KEY="$2" VALUE="$1"
	if [[ "$VALUE" = "*ask" ]]; then
		PREV_VALUE=$(echo "$OLD_ENV" | grep -E -- "^$KEY=" || true)
		if [[ -n "$PREV_VALUE" ]]; then
			VALUE="${PREV_VALUE#*=}"
		else
			ask "Please input value of $KEY" VALUE
		fi
	elif [[ "$VALUE" = "*pass" ]]; then
		if [[ -z "${!KEY}" ]]; then
			die "Requiring environment variable: ${KEY}. which is missing."
		fi
		VALUE="${!KEY}"
	fi
	echo "export $KEY=$VALUE" >> "$PROFILE"
	echo "$KEY=$VALUE" >> "$ENVFILE"
	echo "    ${TEXT_MUTED}$KEY=$VALUE${TEXT_RESET}"
}

echo "" > "$PROFILE"
echo "" > "$ENVFILE"
foreach_object ".environment" generate_environments
echo "  - Created environment file."

create_machine_service

### finished ###
