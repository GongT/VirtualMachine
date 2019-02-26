#!/usr/bin/env bash

export MACHINE_TO_INSTALL=$1
export MACHINE_DEFINE_FILE=$2

set -e

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

source "$(dirname "${BASH_SOURCE[0]}")/include.sh"
title "preparing..."

if [[ -z "$MACHINE_TO_INSTALL" ]] || [[ -z "$MACHINE_DEFINE_FILE" ]] ; then
	echo "Usage: $0 <machine-name> <machine-defined-json-file>" >&2
	exit 1
fi

if ! echo "$MACHINE_TO_INSTALL" | grep -qiE '^[a-z0-9]+$' ; then
	die "Invalid virtual machine name: $MACHINE_TO_INSTALL"
fi

run_main "create-machine.sh"
run_main "download-requires.sh"
run_main "run-compile.sh"
run_main "enable-service.sh"

within_machine "$MACHINE_TO_INSTALL"
create_machine_service
boot
end_within
