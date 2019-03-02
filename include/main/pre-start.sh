#!/usr/bin/env bash

cd "$( dirname "${BASH_SOURCE[0]}" )"
source ../include.sh

PRE_SCRIPT=$(query_json '.prestart')
export ROOT=$(machine_path)

if ! is_null_or_empty "$PRE_SCRIPT" ; then
	echo "\n--------------pre start ($PRE_SCRIPT)--------------\n"
	push_dir "$ROOT"
	source "$(where_host "$PRE_SCRIPT")"
	pop_dir
	echo "\n"
fi
