#!/bin/bash
function add_user_if() {
	echo "Create user $1"
	if ! grep -q -- "$1" /etc/passwd ; then
		useradd --user-group "$1"
	fi
}
add_user_if factorio

chown factorio:factorio /data -R

