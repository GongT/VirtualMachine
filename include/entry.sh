#!/usr/bin/env bash

MACHINE_TO_INSTALL=$1
MACHINE_DEFINE_FILE=$2
if [[ -z "$MACHINE_TO_INSTALL" ]] || [[ -z "$MACHINE_DEFINE_FILE" ]] ; then
	echo "Usage: $0 <machine-name> <machine-defined-json-file>" >&2
	exit 1
fi

set -e

source "$( dirname "${BASH_SOURCE[0]}" )/include.sh"
title "preparing..."

init_machine_base "$MACHINE_TO_INSTALL" "$MACHINE_DEFINE_FILE"
