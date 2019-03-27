#!/usr/bin/env bash

function run_dnf() {
	local __TEMP_DNF_RUN=() CACHE_DIR
	machine_path | path_exists || die "Machine did not exists."

	push_dir "$(machine_path)"
	create_mdnf_run_args "$@"
	screen_run "DNF $1 (...$# args)" "${__TEMP_DNF_RUN[@]}" -y
	pop_dir
}

function create_mdnf_run_args() {
	require_within

	__TEMP_DNF_RUN=(
		/usr/bin/dnf \
			"--setopt=cachedir=../../../../../../../../../../../../../../../../../var/cache/dnf" \
			"--setopt=config_file_path=/etc/dnf/dnf.conf" \
			"--setopt=reposdir=/etc/yum.repos.d" \
			"--releasever=$FEDORA_RELEASE" \
			"--installroot=$(machine_path)" \
			"$@"
		)
	unset CACHE_DIR
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