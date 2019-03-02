#!/usr/bin/env bash

cd "$( dirname "${BASH_SOURCE[0]}" )"
source ../include.sh


if query_condition '.download[]' ; then
	foreach_array '.download' run_download
fi
