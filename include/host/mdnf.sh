#!/usr/bin/env bash

__TEMP_DNF_RUN=()

function run_dnf_server() {
	machine_path | path_exists || die "Machine did not exists."

	push_dir "$(machine_path)"
	mdnf_cache_dir
	create_mdnf_run_args "$@"
	screen_run "DNF $1 (...$# args)" "${__TEMP_DNF_RUN[@]}" -y
	pop_dir
}

function run_dnf_client() {
	machine_path | path_exists || die "Machine did not exists."

	push_dir "$(machine_path)"
	mdnf_cache_dir
	create_mdnf_run_args "$@"
	screen_run "DNF $1 (...$# args)" /usr/bin/ssh server "${__TEMP_DNF_RUN[@]}" -y
	pop_dir
}

function create_mdnf_client() {
	prepare_ssh_client
	mdnf_cache_dir "$HOME"
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

function mdnf_cache_dir() {
	CACHE_DIR=$(realpath --no-symlinks -m --relative-to "${1-$(pwd)}" /var/cache/dnf)
	export CACHE_DIR
}

function create_mdnf_run_args() {
	require_within

	if [[ -z "$CACHE_DIR" ]]; then
		die "CACHE_DIR is required for mdnf"
	fi

	__TEMP_DNF_RUN=(
		/usr/bin/dnf \
			"--setopt=cachedir=${CACHE_DIR}" \
			"--setopt=config_file_path=/etc/dnf/dnf.conf" \
			"--setopt=reposdir=/etc/yum.repos.d" \
			"--releasever=$FEDORA_RELEASE" \
			"--installroot=$(machine_path)" \
			"$@"
		)
}

function run_dnf() {
	if is_inside_namespace; then
		run_dnf_server "$@"
	else
		run_dnf_client "$@"
	fi
}
