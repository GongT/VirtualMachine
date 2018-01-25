#!/bin/bash
systemctl is-active smb --quiet && {
	sleep 1
	systemctl restart smb
} &
systemctl is-active nmb --quiet && {
	sleep 1
	systemctl restart nmb
} &

