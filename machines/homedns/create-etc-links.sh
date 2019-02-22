#!/usr/bin/env bash

set -e
set -x

cd /etc
unlink dnsmasq.conf
unlink hosts
rm -rf dnsmasq.d
rm -rf pdns

ln -s /opt/config/pdns ./
ln -s /opt/config/dnsmasq.conf ./
ln -s /opt/config/hosts ./


