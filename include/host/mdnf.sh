#!/usr/bin/env bash

__TEMP_DNF_RUN=()

function run_dnf_server() {
	machine_should_exists

	create_mdnf_run_args "$@"
	echo "DNF $1 from server, with $# args."
	screen_run "DNF" "${__TEMP_DNF_RUN[@]}" -y
}

function run_dnf_client() {
	machine_should_exists

	create_mdnf_run_args "$@"
	echo "DNF $1 from machine, with $# args."
	screen_run "DNF" /usr/bin/ssh server "${__TEMP_DNF_RUN[@]}" -y
}

function create_mdnf_client() {


	prepare_ssh_client
	create_mdnf_run_args

	local PATH="$(machine_path /usr/local/bin/dnf)"

	echo "#!/bin/bash" > "$PATH"
	echo -n "/usr/bin/ssh server \\" >> "$PATH"
	for i in "${__TEMP_DNF_RUN[@]}"
	do
		echo -n " '$i'" >> "$PATH"
	done
	echo '"$@"' >> "$PATH"
}

function create_mdnf_run_args() {
	local CACHE_DIR="$(realpath -m --relative-to "$(machine_path)" /var/cache/dnf)"
	__TEMP_DNF_RUN=(
		/usr/bin/dnf \
			"--setopt=cachedir=${CACHE_DIR}" \
			"--setopt=config_file_path=/etc/dnf/dnf.conf" \
			"--setopt=reposdir=/etc/yum.repos.d" \
			"--releasever=$FEDORA_RELEASE" \
			"--installroot=$(current_machine)" \
			"$@"
		)
}

if is_inside_namespace; then
	run_dnf_server "$@"
else
	run_dnf_client "$@"
fi
