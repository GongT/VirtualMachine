#!/usr/bin/env bash

cd "$( dirname "${BASH_SOURCE[0]}" )"
source ../include.sh

ACTION="$1"

function create_mdnf_client() {
	prepare_ssh_client
	mdnf_cache_dir "$HOME"
	create_mdnf_run_args

	local T_PATH="$(machine_path /usr/local/bin/dnf)"

	echo "#!/bin/bash" > "$T_PATH"
	echo "/usr/bin/ssh server \\" >> "$T_PATH"
	for i in "${__TEMP_DNF_RUN[@]}"
	do
		echo " '$i' \\" >> "$T_PATH"
	done
	echo '"$@"' >> "$T_PATH"

	chmod a+x "$T_PATH"
}

require_within
case "$ACTION" in
dnf)
	create_mdnf_client
;;
*)
	die "Unknown inject action: $ACTION"
esac
