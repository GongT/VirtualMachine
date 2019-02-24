#!/usr/bin/env bash

function die() {
	echo -e "\e[38;5;9m$@\e[0m" >&2
	exit 1
}

function title_stack_push() {
	__TITLE_STACK+=("$*")
	title "$*"
}
function title_stack_pop() {
	if [[ "${#__TITLE_STACK[@]}" -eq 0 ]]; then
		die "some title_stack_pop is not paired with title_stack_push."
	fi
	local CMD="unset __TITLE_STACK[-1]"
	eval "${CMD}"
	title "${__TITLE_STACK[-1]}"
}

__ALTER_STATUS=0
__ALTER_TITLE_STATUS=0
function screen_alter() {
	if [[ "$__ALTER_STATUS" = 1 ]] ; then
		die "screen already flipped."
	fi
	tput smcup
	clear
	__ALTER_STATUS=1
	if [[ -n "$*" ]]; then
		__ALTER_TITLE_STATUS=1
		title_stack_push "$*"
	fi
}

function screen_normal() {
	if [[ "$__ALTER_STATUS" = 0 ]] ; then
		die "screen never flipped."
	fi
	clear
	tput rmcup
	__ALTER_STATUS=0
	if [[ "$__ALTER_TITLE_STATUS" = 1 ]] ; then
		__ALTER_TITLE_STATUS=0
		title_stack_pop
	fi
}

function screen_run() {
	local TITLE="$1"
	local LOG_FILE="$(init_log_file "screen-run")"
	echo -n "Run: $TITLE - "
	screen_alter "Running: $TITLE."

	echo "------------
title: $TITLE
command to run: $*
machine: $CURRENT_MACHINE
------------

" > "$LOG_FILE"
	set +e
	"$@" | tee -a "$LOG_FILE"
	RET=$?
	set -e
	echo "

------------
exit code: $RET
------------" >> "$LOG_FILE"

	screen_normal
	echo -n "exit with $?. - "

	if [[ ${RET} -eq 0 ]]; then
		echo "Success!"
	else
		echo_red "Failed!"
		echo_red "\t View log at $LOG_FILE"
	fi

	return ${RET}
}

function push_dir() {
	pushd "$1" >/dev/null
}

function pop_dir() {
	popd >/dev/null
}

function title() {
	echo -ne "\033]0;$*\007"
}
