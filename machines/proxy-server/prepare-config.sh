#!/bin/sh

rm -f /etc/privoxy/*.action
rm -f /etc/privoxy/*.filter

sed -i '/^actionsfile/d' /etc/privoxy/config
sed -i '/^filterfile/d' /etc/privoxy/config
sed -i '/^logfile/d' /etc/privoxy/config
sed -i '/^debug/d' /etc/privoxy/config

echo 'actionsfile /config/user.action' >> /etc/privoxy/config
echo 'logfile /dev/stdout' >> /etc/privoxy/config
echo '
debug     1 # Log the destination for each request Privoxy let through. See also debug 1024.
debug  4096 # Startup banner and warnings
debug  8192 # Non-fatal errors
' >> /etc/privoxy/config
