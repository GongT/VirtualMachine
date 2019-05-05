#!/usr/bin/env bash

cd /opt/qBittorrent

mkdir -p cache
chown media_rw . -R

[[ -L config ]] && unlink config
[[ -e config ]] && rm -rf config
ln -s /mnt/config
chown media_rw /mnt/config -R

localectl set-locale zh_CN.UTF-8
