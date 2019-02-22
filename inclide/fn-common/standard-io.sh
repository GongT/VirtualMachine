#!/usr/bin/env bash

function die() {
	echo -e "\e[38;5;9m$@\e[0m" >&2
	exit 1
}

function screen_alter() {
	tput smcup
	clear
}

function screen_normal() {
	clear
	tput rmcup
}

function push_dir() {
	pushd "$1" >/dev/null
}

function pop_dir() {
	popd >/dev/null
}