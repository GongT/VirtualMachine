#!/bin/bash

set -e

## wait for enough time for mountpoints
TRY=1
while [[ -z "$PROC" ]]; do
	for I in /proc/*/cmdline ; do
		echo "test: $I"
		if ! echo "$I" | grep -qE "/proc/[0-9]+/" ; then
			continue
		fi
		if grep -q "agetty" "$I" ; then
			echo "found agetty!"
			PROC=$(dirname "$I")
			break 2;
		fi
	done
	if [[ "$TRY" -gt 5 ]]; then
		echo "can not get atty?" >&2
		exit 1
	fi
	sleep 3s
	TRY=$(($TRY + 1))
done

echo "tty=$PROC"

rm -f /var/log/samba/log.nmbd || true

echo "[global]
 	log level = 2
	workgroup = WORKGROUP
	server string = shabao's SAMBA share server
	netbios name = $(< /etc/hostname)
	interfaces = lo host0
	security = user
	map archive = no
	map hidden = no
	map read only = no
	map system = no
	vfs objects = acl_xattr
	map acl inherit = yes
	store dos attributes = yes
	passdb backend = tdbsam
	load printers = no
	name resolve order = bcast lmhosts wins host
	local master = yes
	wins support = yes
	preferred master = yes
	valid users = +smbusers
	admin users = +smbusers
	write list = +smbusers
	username map = /opt/scripts/username.map
	acl allow execute always = yes
	ntlm auth = yes
	recycle:touch = yes
	recycle:keeptree = yes
	recycle:versions = no
	recycle:excludedir = .\$samba
" > /etc/samba/smb.conf

for I in /samba_share_mountpoints/*/ ; do
	create_section "$I"
done
for I in /samba_share_drives/*/ ; do
	create_section "$I"
done

function create_section() {
	local PATH="$1" OPTIONS LABEL
	local LABEL_FILE="${I}/.\$samba/disklabel.txt"
	if [[ -e "$LABEL_FILE" ]]; then
		LABEL=$(< "$LABEL_FILE")
	else
		LABEL="$(basename "${PATH}")"
		if [[ "$LABEL" = "shm" ]]; then
			LABEL="System Memory"
		fi
	fi

	local OPTIONS_FILE="${I}/.\$samba/disklabel.txt"
	if [[ -e "$OPTIONS_FILE" ]]; then
		OPTIONS="$(echo $(< "$OPTIONS_FILE"))"
	else
		OPTIONS="acl_xattr"
	fi

	echo "
[$(basename "${PATH}")]
	comment = ${LABEL}
	path = ${PATH}/
	writable = yes
	read only = no
	vfs objects = $OPTIONS
	nt acl support = yes
	public = yes
	inherit acls = yes
	browseable = yes
	create mask = 0644
	directory mask = 0755
	recycle:repository = ${PATH}/.\$samba/recycle/%U
	recycle:touch = no
	recycle:keeptree = yes
	recycle:versions = no
	recycle:excludedir = .\$samba
" >> /etc/samba/smb.conf
}
