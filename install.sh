#!/usr/bin/env bash

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source lib/functions.sh

if [ -z "$1" ]; then
	die "Usage: $0 <machine>"
fi

if [ -e "./machines/$1/install.sh" ]; then
	set -e
	export INSTALL_ROOT="$(realpath "./machines/$1")"
	cd "./machines/$1"
	source "install.sh" || die "Install failed."
else
	die "No machine install script: $1"
fi


