#!/usr/bin/env bash


echo "
export HTTP_PROXY="$PROXY" HTTPS_PROXY="$PROXY" ALL_PROXY="$PROXY" http_proxy="$PROXY" https_proxy="$PROXY" all_proxy="$PROXY"

" > /etc/profile.d/99-proxy.sh

