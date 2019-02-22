#!/bin/bash

set -e

cd /opt/php-source/modules/php-systemd

mkdir -p /opt/php/modules
mkdir -p /opt/php/config

phpize
./configure --with-systemd --prefix=/opt/php
make -j
mv modules/*.so /opt/php/modules

echo 'extension=systemd.so' > /opt/php/config/60-systemd.ini
