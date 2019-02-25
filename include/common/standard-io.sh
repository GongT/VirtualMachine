#!/usr/bin/env bash

function die() {
	echo "\e[38;5;9m$@\e[0m" >&2
	exit 100
}

__TITLE_STACK=()
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
	if [[ "${#__TITLE_STACK[@]}" -eq 0 ]]; then
		title "Untitled script"
	fi
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
	local TITLE="$1" LOG_FILE
	shift
	LOG_FILE="$(init_log_file "screen-run")"
	echo -n "$TITLE - "
	screen_alter "Running: $TITLE."

	echo "------------
title: $TITLE
command to run: $*
pwd: $(pwd)
machine: $CURRENT_MACHINE
log file: $LOG_FILE
------------

" | tee "$LOG_FILE" >&2
	set +e
	cat | "$@" 2>&1 | tee -a "$LOG_FILE"
	RET=$?
	set -e
	echo "

------------
exit code: $RET
------------" >> "$LOG_FILE"

	screen_normal

	if [[ ${RET} -eq 0 ]]; then
		echo "${TEXT_OK}Success!${TEXT_RESET}${TEXT_MUTED} (log is at $LOG_FILE)${TEXT_RESET}"
	else
		echo "exit with $RET. - ${TEXT_ERROR}Failed!${TEXT_RESET}"
		echo "\t ${TEXT_ERROR}View log at $LOG_FILE${TEXT_RESET}"
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
	echo -n "\033]0;$*\007"
}

function echo() {
	builtin echo -e "$@"
}
