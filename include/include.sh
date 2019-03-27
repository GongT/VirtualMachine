#!/usr/bin/env bash

set -e
set -o pipefail

export SCRIPT_INCLUDE_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

pushd "$SCRIPT_INCLUDE_ROOT" >/dev/null
source 'common/constant.sh'
source 'common/download-wget.sh'
source 'common/environment.sh'
source 'common/main.sh'
source 'common/standard-io.sh'
source 'common/systemd-control.sh'
source 'common/text-edit.sh'
if [[ "$(systemd-detect-virt)" != "systemd-nspawn" ]]; then
	source 'host/download.sh'
	source 'host/download-git.sh'
	source 'host/download-github.sh'
	source 'host/download-helper.sh'
	source 'host/extract.sh'
	source 'host/host-path.sh'
	source 'host/json-parse.sh'
	source 'host/mdnf.sh'
	source 'host/sshd-control.sh'
	source 'host/system.sh'
	source 'host/virtual-machine-control.sh'
fi
popd >/dev/null
