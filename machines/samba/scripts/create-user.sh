#!/usr/bin/env bash

set -e

function create-all-user() {
	local USER="$1"
	local PASSWD="$2"
	if ! grep -q -- "$USER" "/etc/passwd" ; then
		useradd "$USER" -g 0 -G root,smbusers
	fi

	echo "$PASSWD" | passwd --stdin "$USER"

	echo -e "$PASSWD\n$PASSWD\n" | pdbedit "--user=$USER" "--fullname=$USER" --create
}

if ! grep -q -- smbusers /etc/group ; then
	groupadd smbusers
fi

if [[ -z "$PASSWORD" ]]; then
	echo "Error: no PASSWORD."
	exit 1
fi

create-all-user GongT "$PASSWORD"
create-all-user Guest "123456"
