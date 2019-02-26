#!/usr/bin/env bash

set -e

/usr/lib/systemd/systemd-networkd-wait-online --timeout=15

if ! [[ -e /etc/gitconfig ]]; then
	echo '
[user]
        name = GongT
        email = admin@gongt.me
' > /etc/gitconfig
fi

set -x

cd /opt/JetBrains
if ! [[ -e .git ]]; then
	git clone git@github.com:GongT/jetbrains-bootstrap-scripts.git /tmp/temp-repo
	mv /tmp/temp-repo/.git ./
	git reset --hard
fi

clone_if() {
	local GIT="$1" LOCAL="$2"

	mkdir -p "$LOCAL"
	cd "$LOCAL"
	if ! [[ -e .git ]]; then
		git clone "git@github.com:$GIT.git" .
	fi
}

clone_if GongT/simple-settings-repository /opt/JetBrains/DATA/PhpStorm/simple-settings-repository
clone_if GongT/idea-settings /opt/JetBrains/DATA/PhpStorm/simple-settings-repository/repo
