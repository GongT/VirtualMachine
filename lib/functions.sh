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
	tput smcup
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
