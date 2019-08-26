#!/usr/bin/env bash

set -e

function create-all-user() {
	local USER="$1"
	local PASSWD="$2"
	echo "Ensure user $USER:"
	if ! grep -q -- "$USER" "/etc/passwd" ; then
		echo "  linux user does not exists. create it now..."
		useradd "$USER" -g 0 -G smbusers,users
	fi

	echo "  set linux password to $PASSWD."
	echo "$PASSWD" | passwd --stdin "$USER"

	echo "  set pdb password."
	echo -e "$PASSWD\n$PASSWD\n" | pdbedit "--user=$USER" "--fullname=$USER" --create
	echo "User $USER created."
}

{
	echo "#!/usr/bin/env bash"
	declare -f create-all-user
 	echo 'create-all-user "$@"'
} > /usr/local/bin/create-all-user
chmod a+x /usr/local/bin/create-all-user


if ! grep -q -- smbusers /etc/group ; then
	groupadd smbusers
fi

if [[ -z "$PASSWORD" ]]; then
	echo "Error: no PASSWORD."
	exit 1
fi

create-all-user GongT "$PASSWORD"
create-all-user QQ "QQ920223"
create-all-user Guest "123456"

