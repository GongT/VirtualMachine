#!/usr/bin/env bash

echo SHABAO-SHARE > /etc/hostname

function create-all-user() {
	local USER="$1"
	local PASSWD="$2"
	useradd "$USER" -g 0 -G root,smbusers --password "$PASSWD"
	echo -e "$PASSWD\n$PASSWD\n" | pdbedit "--user=$USER" "--fullname=$USER" --create
}

groupadd smbusers

create-all-user GongT "#0624UFO"
create-all-user Guest "123456"



