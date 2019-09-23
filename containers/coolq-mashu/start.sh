#!/bin/bash

docker run --rm -a stdout -a stderr \
	-p 29000:9000 \
	-p 21567:21567 \
	--name coolq-mashu \
	-v /data/AppData/data/coolq/mashu:/home/user/coolq \
	-e "VNC_PASSWD=123456" -e "COOLQ_ACCOUNT=1427899546" \
	coolq/wine-coolq

