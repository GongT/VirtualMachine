#!/usr/bin/env bash

cd opt
mkdir -p nginx/modules
mkdir -p nginx/special-modules
cd nginx

download-source nginx http://hg.nginx.org/nginx/archive/tip.tar.gz

download-source special-modules/njs http://hg.nginx.org/njs/archive/tip.tar.gz

clone modules/nginx-rtmp-module https://github.com/arut/nginx-rtmp-module.git

pushd modules/nginx-rtmp-module
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
popd

clone modules/memc-nginx-module https://github.com/openresty/memc-nginx-module.git
clone modules/ngx_cache_purge https://github.com/FRiCKLE/ngx_cache_purge.git
clone modules/nginx-http-slice https://github.com/alibaba/nginx-http-slice.git

export BUILD_TYPE=Release
download-source modules/incubator-pagespeed-ngx https://github.com/apache/incubator-pagespeed-ngx/archive/latest-stable.tar.gz
modules/incubator-pagespeed-ngx
BIT_SIZE_NAME=x64 eval "SOURCE=\"$(<modules/incubator-pagespeed-ngx/PSOL_BINARY_URL)\" "
download-source modules/incubator-pagespeed-ngx/psol "${SOURCE}"

clone modules/echo-nginx-module https://github.com/openresty/echo-nginx-module.git
clone modules/headers-more-nginx-module https://github.com/openresty/headers-more-nginx-module.git
