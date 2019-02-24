#!/usr/bin/env bash

set -e

export SCRIPT_INCLUDE_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

pushd "$SCRIPT_INCLUDE_ROOT" >/dev/null
source 'common/standard-io.sh'
if [[ "$(systemd-detect-virt)" != "systemd-nspawn" ]]; then
	source 'host/download.sh'
	source 'host/extract.sh'
	source 'host/output-control.sh'
	source 'host/virtual-machine-control.sh'
fi
source 'common/systemd-control.sh'
