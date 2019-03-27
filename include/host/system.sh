#!/usr/bin/env bash

function ensure_user() {
	local U_ID=$1 U_NAME=$2 G_ID=$3 MP=$(machine_path ".")
	if cat "$(machine_path "/etc/passwd")" | grep -- "$U_NAME" | grep -q -- ":$U_ID:$G_ID:" ; then
		echo "Group $U_NAME exists with id $U_ID"
	else
		useradd --root "$MP" --gid "$G_ID" --no-create-home --no-user-group --uid "$U_ID" "$U_NAME"
		echo "Created $U_NAME."
	fi
}

function ensure_group() {
	require_within
	local G_ID=$1 G_NAME=$2 MP=$(machine_path ".")
	if cat "$(machine_path "/etc/group")" | grep -- "$G_NAME" | grep -q -- ":$G_ID:" ; then
		echo "Group $G_NAME exists with id $G_ID"
	else
		groupadd --root "$MP" -g "$G_ID" "$G_NAME"
		echo "Created $G_NAME."
	fi
}
