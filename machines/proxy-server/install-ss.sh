#!/usr/bin/env bash

set -e

active-network

mkdir -p /data/shadowsocks

dpush /data/shadowsocks
download-source "source" "$1" || die "can not download shadowsocks source files"

dpush source
./configure --prefix=/data/shadowsocks --disable-documentation
make -j$(nproc)
make install

dpop
dpop
