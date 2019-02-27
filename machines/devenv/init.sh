#!/usr/bin/env bash

set -e

/usr/lib/systemd/systemd-networkd-wait-online --timeout=15

#### prevent git require user name and fail
if ! [[ -e /etc/gitconfig ]]; then
	echo '
[user]
        name = GongT
        email = admin@gongt.me
' > /etc/gitconfig
fi

set -x

#### clone idea loader scripts
cd /opt/JetBrains
if ! [[ -e .git ]]; then
	git clone git@github.com:GongT/jetbrains-bootstrap-scripts.git /tmp/temp-repo
	mv /tmp/temp-repo/.git ./
	git reset --hard
fi
bash install.sh

clone_if() {
	local GIT="$1" LOCAL="$2"

	mkdir -p "$LOCAL"
	cd "$LOCAL"
	if [[ -e .git ]]; then
		git pull
	else
		git clone "git@github.com:$GIT.git" .
	fi
}

#### clone idea settings
clone_if GongT/simple-settings-repository /opt/JetBrains/DATA/PhpStorm/simple-settings-repository
clone_if GongT/idea-settings /opt/JetBrains/DATA/PhpStorm/simple-settings-repository/repo

#### restore idea settings
cd /opt/JetBrains/DATA/PhpStorm/simple-settings-repository
[[ -L "config" ]] && unlink config
[[ -e "config" ]] && rm -rf config
ln -s ../config
./restore.sh

#### linux-toolbox
ln -s /usr/local/bin/dnf /usr/bin/dnf
clone_if GongT/linux-toolbox /data/DevelopmentRoot/github.com/GongT/linux-toolbox
./install_environment.sh
