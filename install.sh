#!/usr/bin/env bash

MACHINE_TO_INSTALL=$1
if [[ -z "$MACHINE_TO_INSTALL" ]]; then
	echo "Usage: $0 <machine-name-to-install>" >&2
	exit 1
fi

cd "$( dirname "${BASH_SOURCE[0]}" )"
if ! [[ -d "machines/$MACHINE_TO_INSTALL" ]]; then
	echo "Required machine ($MACHINE_TO_INSTALL) not exists. (want: $(pwd)/machines/$MACHINE_TO_INSTALL)" >&2
	exit 1
fi

source "include/include.sh"
cd "machines/$MACHINE_TO_INSTALL"
set_template_source "$(pwd)"

exec bash "$SCRIPT_INCLUDE_ROOT/entry.sh" "$MACHINE_TO_INSTALL" "$(where_host "${MACHINE_TO_INSTALL}.container.json5")"
