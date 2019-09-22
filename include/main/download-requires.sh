#!/usr/bin/env bash

cd "$( dirname "${BASH_SOURCE[0]}" )"
source ../include.sh


if query_condition '.download[]' ; then
	foreach_array '.download' run_download
fi

function install_with_dnf() {
	run_dnf install "$(machine_path "$1")"
}

if query_condition '.install.downloaded[]' ; then
	foreach_array '.install.downloaded' install_with_dnf
fi
