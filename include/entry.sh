#!/usr/bin/env bash

export MACHINE_TO_INSTALL=$1
export MACHINE_DEFINE_FILE=$2

set -e
set -o pipefail

source "$(dirname "${BASH_SOURCE[0]}")/include.sh"
title "preparing..."

handle_exit

if [[ -z "$MACHINE_TO_INSTALL" ]] || [[ -z "$MACHINE_DEFINE_FILE" ]] ; then
	echo "Usage: $0 <machine-name> <machine-defined-json-file>" >&2
	exit 1
fi

if ! echo "$MACHINE_TO_INSTALL" | grep -qiE '^[a-z0-9_-]+$' ; then
	die "Invalid virtual machine name: $MACHINE_TO_INSTALL"
fi

tput rmcup
echo -en "\ec"
clear

within_machine "$MACHINE_TO_INSTALL"

clear_install_logs
clear_machine_install_logs

run_main "create-machine.sh"
run_main "create-special.sh"
run_main "download-requires.sh"
run_main "run-compile.sh"
run_main "enable-service.sh"

run_main "pre-start.sh"

boot

end_within

tput rmcup
echo "Done."
