#!/usr/bin/env bash


mkdir -p /opt/php/modules
mkdir -p /opt/php/config

cd /opt/source/php/modules/php-systemd
rm -rf modules/
phpize
./configure --with-systemd --prefix=/opt/php
make -j
cp modules/* /opt/php/modules

echo 'extension=systemd.so' > /opt/php/config/60-systemd.ini

