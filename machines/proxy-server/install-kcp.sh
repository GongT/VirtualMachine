#!/usr/bin/env bash

cd data
download-file "kcp-binary.tar.gz" "$1" || die "can not download kcp binary files"
mkdir -p ./kcptun
tar -xf "kcp-binary.tar.gz" -C ./kcptun
cd ..
