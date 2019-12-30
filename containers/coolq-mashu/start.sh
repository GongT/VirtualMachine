#!/bin/bash

ENABLE_PROXY=()

# ENABLE_PROXY=(-e "http_proxy=http://10.0.0.1:3271" -e "https_proxy=http://10.0.0.1:3271")

docker run --rm -a stdout -a stderr \
	-p 29000:9000 \
	-p 21567:21567 \
	--name coolq-mashu \
	-v /data/AppData/data/coolq/mashu:/home/user/coolq \
	-e "VNC_PASSWD=123456" -e "COOLQ_ACCOUNT=1541468254" \
	"${ENABLE_PROXY[@]}" \
	coolq/wine-coolq

