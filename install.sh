#!/usr/bin/env bash

set -e

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source lib/functions.sh

if [ -z "$1" ]; then
	die "Usage: $0 <machine>"
fi

if [ ! -e "/usr/local/bin/mdnf" ]; then
	echo "#!/bin/bash

source '$(pwd)/lib/mdnf.sh'

mdnf \"\$@\"
" >  /usr/local/bin/mdnf
	chmod a+x /usr/local/bin/mdnf
fi

if [ -e "./machines/$1/install.sh" ]; then
	set -e
	export INSTALL_ROOT="$(realpath "./machines/$1")"
	cd "./machines/$1"
	source "install.sh" || die "Install failed."
else
	die "No machine install script: $1"
fi


