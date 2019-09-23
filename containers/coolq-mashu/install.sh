#!/bin/bash

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"


{
	cat ./docker.service
	echo "WorkingDirectory=$(pwd)"
} >/usr/lib/systemd/system/coolq-mashu.service

systemctl daemon-reload
systemctl enable coolq-mashu.service

