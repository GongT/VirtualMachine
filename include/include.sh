#!/usr/bin/env bash

set -e

export SCRIPT_INCLUDE_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

pushd "$SCRIPT_INCLUDE_ROOT" >/dev/null
source 'common/constant.sh'
source 'common/environment.sh'
source 'common/standard-io.sh'
source 'common/systemd-control.sh'
source 'common/text-edit.sh'
if [[ "$(systemd-detect-virt)" != "systemd-nspawn" ]]; then
	source 'host/create-machine.sh'
	source 'host/download.sh'
	source 'host/extract.sh'
	source 'host/host-path.sh'
	source 'host/json-parse.sh'
	source 'host/mdnf.sh'
	source 'host/sshd-control.sh'
	source 'host/virtual-machine-control.sh'
fi
popd >/dev/null

# echo an error message before exiting
trap '
RET=$?
if [[ "$RET" -ne 0 ]]; then
	echo "* the command ${TEXT_INFO}${BASH_COMMAND}${TEXT_RESET} has filed with exit code $RET."
	exit "$RET"
else
	echo "Done."
fi
' EXIT
