#!/usr/bin/env bash

function create-all-user() {
	local USER="$1"
	local PASSWD="$2"
	useradd "$USER" -g 0 -G root,smbusers --password "$PASSWD"
	echo -e "$PASSWD\n$PASSWD\n" | pdbedit "--user=$USER" "--fullname=$USER" --create
}

groupadd smbusers

PASSWORD=$(ask "Please input password")
create-all-user GongT "$PASSWORD"
create-all-user Guest "123456"
