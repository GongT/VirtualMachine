#!/usr/bin/env bash

function die() {
	echo -e "\e[38;5;9m$@\e[0m" >&2
	exit 1
}

function mkdir() {
	echo mkdir "$@" >&2
	/bin/mkdir "$@"
}

function staff-file() {
	echo "${INSTALL_ROOT}/$1"
}

function vm-file() {
	local F="${2#/}"
	echo "${LIB_MACHINE}/$1/$F"
}

function screen-run() {
	echo -e "SCREEN_RUN: $*"
	tput smcup
	echo -e "\ec"
	"$@" 2>&1 | tee .run.error.log
	RET=${PIPESTATUS[0]}
	tput rmcup
	
	if [ ${RET} -ne 0 ]; then
		cat .run.error.log >&2
		echo -e "\e[38;5;9mthis command failed:\e[0m $*" >&2
	fi
	unlink .run.error.log
	
	return ${RET}
}

function download-file() {
	local URL="$1"
	local BASE="$(basename "${URL}")"
	local TARGET=$(vm-file "${MACHINE}" "/mnt/install/${BASE}")
	if [ -e "${TARGET}" ]; then
		return
	fi
	
	mkdir -p "$(dirname "${TARGET}")"
	wget "${URL}" -c -O "${TARGET}.downloading"
	RET=$?
	
	if [ ${RET} -ne 0 ]; then
		return ${RET}
	fi
	
	mv "${TARGET}.downloading" "${TARGET}"
}
