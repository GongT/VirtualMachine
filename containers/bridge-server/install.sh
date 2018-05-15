#!/usr/bin/env bash

set -e

PASSWORD=$(md5sum ~/.ssh/my-keys/home.rsa  | awk '{print $1}')

cat > config.json <<KCP_CONFIG
{
        "crypt": "xor",
        "conn": 10,
        "localaddr": "0.0.0.0:45678",
        "remoteaddr": "127.0.0.1:",
        "key": "65e6KyayugmByMj4k54rk"
}
KCP_CONFIG
