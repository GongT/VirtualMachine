#!/usr/bin/env bash


function run_main() {
	local FN="$1"
	shift
	bash "${SCRIPT_INCLUDE_ROOT}/main/$FN" "$@"
}

function source_main() {
	local FN="$1"
	shift
	source "${SCRIPT_INCLUDE_ROOT}/main/$FN" "$@"
}

function main_exists() {
	local FN="$1"
	shift
	[[ -e "${SCRIPT_INCLUDE_ROOT}/main/$FN" ]]
}
