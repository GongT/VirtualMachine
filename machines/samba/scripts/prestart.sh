#!/bin/bash

TRY=1
while [ -z "$PROC" ]; do
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
	if [ "$TRY" -gt 5 ]; then
		echo "can not get atty?" >&2
		exit 1
	fi
	sleep 3s
	TRY=$(($TRY + 1))
done

echo "tty=$PROC"

rm -f /var/log/samba/log.nmbd || true

echo "[global]" > /etc/samba/smb.conf
# echo "	log file = ${PROC}/fd/1" >> /etc/samba/smb.conf
cat /opt/smb.conf.global >> /etc/samba/smb.conf

cat /opt/development-root.conf >> /etc/samba/smb.conf

cd /drives
for I in */ ; do
	if [ -e "${I}.disklabel" ]; then
		DISKLABEL=$(< "${I}.disklabel")
	else
		DISKLABEL="${I%/}"
	fi

	echo "
[${I%/}]
	comment = ${DISKLABEL}
	path = /drives/${I}
	writable = yes
	read only = no
	vfs objects = acl_xattr recycle
	nt acl support = yes
	public = yes
	inherit acls = yes
	browseable = yes
	create mask = 0644
	directory mask = 0755
	recycle:repository = /drives/${I}.recycle/%U
	recycle:touch = no
	recycle:keeptree = yes
	recycle:versions = no
	recycle:excludedir = .recycle

" >> /etc/samba/smb.conf
done
