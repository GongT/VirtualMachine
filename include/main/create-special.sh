#!/usr/bin/env bash

cd "$( dirname "${BASH_SOURCE[0]}" )"
source ../include.sh

require_within

function build_dyn_blocks_args() {
	local TARGET=

}

if [[ "$(query_json ".specialConfig.dynamicBlockDevice | length")" -ne 0 ]]; then
	foreach_array ".specialConfig.dynamicBlockDevice" build_dyn_blocks_args
fi


