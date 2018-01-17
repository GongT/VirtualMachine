#!/usr/bin/env bash

hostnamectl set-hostname DNS

cd /etc

if [ ! -e named.conf.backup ]; then
	mv named.conf named.conf.backup
fi

cat named.conf.backup \
 | sed 's/allow-query.*\;/include "\/etc\/named\/overwrite.conf";/g' \
 | sed '/logging {/ { :a;N; /^};/M!ba ; d }' \
 | sed '/dnssec/d' \
 > named.conf \
 || die "can not parse named.conf"
echo 'include "/etc/named/zones.conf";' >> named.conf
echo 'include "/etc/named/logs.conf";' >> named.conf

cd /etc/named

echo "
listen-on port 53 { any; };
listen-on-v6 port 53 { any; };
forwarders {
	10.0.0.1;
};
allow-update { 127.0.0.1; };
allow-query  { any; };
masterfile-format text;
dnssec-enable no;
" > overwrite.conf

echo '
logging {
  channel bind_log {
    file "/var/log/named.log";
    severity info;
    print-category yes;
    print-severity yes;
    print-time yes;
  };
  category default { bind_log; };
  category update { bind_log; };
  category update-security { bind_log; };
  category security { bind_log; };
  category queries { bind_log; };
  category lame-servers { bind_log; };
};
' > logs.conf

echo "
include \"/etc/named/zones/main.conf\";
include \"/etc/named/zones/services.conf\";
" > zones.conf

mkdir -p zones
cd zones

echo '' > main.conf

echo '
zone "service.gongt.me" {
       type master;
       file "/etc/named/zones/db.service.gongt.me";
       journal "/etc/named/zones/journal.service.gongt.me";
};
' > services.conf

echo "\$TTL 1D
service.gongt.me.	IN SOA	@	gongt.me. (
		1		; serial
		1D		; refresh
		1H		; retry
		1D		; expire
		1D		; minimum
)
		IN NS		ns1.he.net.
" > db.service.gongt.me
