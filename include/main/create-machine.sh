#!/usr/bin/env bash

cd "$( dirname "${BASH_SOURCE[0]}" )"
source ../include.sh

echo -e "Initialize virtual machine ${TEXT_INFO}$MACHINE_TO_INSTALL${TEXT_RESET} with script:\n    ${TEXT_MUTED}$MACHINE_DEFINE_FILE${TEXT_RESET}"

### init variables (json) ###
within_machine "$MACHINE_TO_INSTALL"
create_machine_json "$MACHINE_DEFINE_FILE"
shutdown

### base system ###
echo "Initializing base system..."
TESTING_PATH="$(machine_path /bin/bash)"
if [[ -e "$TESTING_PATH" ]] ; then
	echo "  - Already exists"
else
	echo "  - Base environment missing, installing..."
	run_dnf install systemd bash
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
source_main create-nspawn-file.sh "$MACHINE_TO_INSTALL"
echo "  - Created nspawn file."

### dnf install packages ###
install_package \
	"$(query_json ".install.packages[]")" \
	"$(query_json ".install.packagesFile")"
echo "  - Required packages installed."

### inject custom tool like dnf ###
function call_inject_script() {
	local WHAT
	WHAT="$(cat)"
	run_main "inject.sh" "$WHAT"
	echo "  - inject tool: $WHAT"
}
foreach_array '.install.inject' call_inject_script

### copy files from current dir to remote ###
function call_copy_files() {
	local FROM="$1" TARGET="$(cat)" FROM_ABS TARGET_ABS COUNT
	echo "Copy '${FROM}' to '${TARGET}'..."
	FROM_ABS=$(where_host "$FROM")
	TARGET_ABS=$(machine_path "$TARGET")
	echo -n "${TEXT_MUTED}" >&2
	COUNT=$(cp -vr -- "$FROM_ABS" "$TARGET_ABS" | tee /dev/stderr | wc -l)
	echo -n "${TEXT_RESET}" >&2
	echo "  ${COUNT} files copied."
}
foreach_object '.install.copyFiles' call_copy_files

### copy init config files to AppData ###
INIT_CONFIG_PATH="$(query_json ".bind.initConfig")"
if ! is_null_or_empty "$INIT_CONFIG_PATH" ; then
	CONFIG_STORE="$(where_config)"
	mkdir "$CONFIG_STORE"
	# -n / --no-clobber: no overwrite
	cp --no-clobber -vf "$(where_host "${INIT_CONFIG_PATH}")/." "$CONFIG_STORE"
fi

### create symlink from /etc or /var/log or ... to /mnt/xxx
function create_bind_link() {
	local SOURCE="$4" LINK="$5" VALUE TARGET
	VALUE="$(cat)"
	TARGET="$(machine_path "${LINK}/${VALUE}")"
	if [[ -L "$TARGET" ]] ; then
		unlink "$TARGET"
	fi
	if [[ -e "$TARGET" ]] ; then
		rm -rf "$TARGET"
	fi
	echo "    ${TEXT_MUTED}create link: ${TARGET}${TEXT_RESET}"
	ln -s "$(realpath --no-symlinks -m "${LINK}/${VALUE}")"
}
foreach_array ".bind.socket" create_bind_link "/mnt/socket" "/var/run"
foreach_array ".bind.config" create_bind_link "/mnt/config" "/etc"
foreach_array ".bind.log" create_bind_link "/mnt/log" "/var/log"

### finished ###
end_within