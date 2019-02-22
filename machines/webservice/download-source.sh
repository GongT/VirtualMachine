#!/usr/bin/env bash

pushd opt &>/dev/null
mkdir -p nginx-source/modules
mkdir -p nginx-source/special-modules
pushd nginx-source &>/dev/null

download-github nginx nginx/nginx

download-master special-modules/njs nginx/njs

download-master modules/nginx-rtmp-module arut/nginx-rtmp-module

pushd modules/nginx-rtmp-module &>/dev/null
echo '
diff -Nur a/ngx_rtmp_eval.c b/ngx_rtmp_eval.c
--- a/ngx_rtmp_eval.c	2018-06-02 19:23:28.993466673 +0200
+++ b/ngx_rtmp_eval.c	2018-06-02 19:23:26.532371311 +0200
@@ -166,6 +166,7 @@
                         state = ESCAPE;
                         continue;
                 }
+				 /* fall through */
 
             case ESCAPE:
                 ngx_rtmp_eval_append(&b, &c, 1, log);
' | patch -b ngx_rtmp_eval.c
popd &>/dev/null

download-master modules/memc-nginx-module openresty/memc-nginx-module
download-master modules/ngx_cache_purge FRiCKLE/ngx_cache_purge

export BUILD_TYPE=Release
download-source modules/incubator-pagespeed-ngx https://github.com/apache/incubator-pagespeed-ngx/archive/latest-stable.tar.gz
BIT_SIZE_NAME=x64 eval "SOURCE=\"$(<modules/incubator-pagespeed-ngx/PSOL_BINARY_URL)\" "
download-source modules/incubator-pagespeed-ngx/psol "${SOURCE}"

download-master modules/echo-nginx-module openresty/echo-nginx-module
download-master modules/headers-more-nginx-module openresty/headers-more-nginx-module

download-master modules/lua-nginx-module openresty/lua-nginx-module
download-master modules/stream-lua-nginx-module openresty/stream-lua-nginx-module
download-master modules/ngx_devel_kit simplresty/ngx_devel_kit

popd &>/dev/null

mkdir -p php-source/modules
pushd php-source &>/dev/null

download-master modules/php-systemd systemd/php-systemd
