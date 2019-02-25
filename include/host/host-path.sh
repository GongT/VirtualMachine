#!/usr/bin/env bash

TEMPLATE_SOURCE_PATH=""
function set_template_source() {
	export TEMPLATE_SOURCE_PATH="$1"
}

function where_host() {
	realpath --no-symlinks "$TEMPLATE_SOURCE_PATH/$1"
}
