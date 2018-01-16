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
