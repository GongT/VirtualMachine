#!/usr/bin/env bash

function run_dnf_server() {
	local __TEMP_DNF_RUN=() CACHE_DIR
	machine_path | path_exists || die "Machine did not exists."

	push_dir "$(machine_path)"
	mdnf_cache_dir
	create_mdnf_run_args "$@"
	screen_run "DNF $1 (...$# args)" "${__TEMP_DNF_RUN[@]}" -y
	pop_dir
}

function run_dnf_client() {
	local __TEMP_DNF_RUN=() CACHE_DIR
	machine_path | path_exists || die "Machine did not exists."

	push_dir "$(machine_path)"
	mdnf_cache_dir
	create_mdnf_run_args "$@"
	screen_run "DNF $1 (...$# args)" /usr/bin/ssh server "${__TEMP_DNF_RUN[@]}" -y
	pop_dir
}

function mdnf_cache_dir() {
	CACHE_DIR=$(realpath --no-symlinks -m --relative-to "${1-$(pwd)}" /var/cache/dnf)
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
	unset CACHE_DIR
}

function run_dnf() {
	if is_inside_namespace; then
		run_dnf_client "$@"
	else
		run_dnf_server "$@"
	fi
}

function install_package() {
	local PACKAGES="$1" PACKAGE_LIST="$2"
	if is_null_or_empty "$PACKAGES" ; then
		PACKAGES=""
	fi
	if ! is_null_or_empty "$PACKAGE_LIST" ; then
		PACKAGES+=$(cat "$(realpath -m "$(where_host "$PACKAGE_LIST")")")
	fi
	if is_null_or_empty "$PACKAGES" ; then
		return
	fi

	if [[ -n "$PACKAGES" ]]; then
		{
			echo "update"
			echo -n "install "
			echo ${PACKAGES}
			echo "run"
			echo "exit"
		} | run_dnf shell
	fi
}