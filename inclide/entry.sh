#!/usr/bin/env bash

set -e

export SCRIPT_INCLUDE_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

pushd "$SCRIPT_INCLUDE_ROOT" >/dev/null
source "fn-common/standard-io.sh"
if [[ "$(systemd-detect-virt)" = "systemd-nspawn" ]]; then
else
	source fn-host/download.sh
	source fn-host/extract.sh
	source fn-host/output-control.sh
	source fn-host/virtual-machine-control.sh
fi

