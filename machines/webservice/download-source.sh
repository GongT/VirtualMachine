#!/usr/bin/env bash

cd opt
mkdir -p nginx/modules
mkdir -p nginx/special-modules
cd nginx

download-source nginx http://hg.nginx.org/nginx/archive/tip.tar.gz

download-source special-modules/njs http://hg.nginx.org/njs/archive/tip.tar.gz

clone modules/nginx-rtmp-module https://github.com/arut/nginx-rtmp-module.git
clone modules/memc-nginx-module https://github.com/openresty/memc-nginx-module.git
clone modules/ngx_cache_purge https://github.com/FRiCKLE/ngx_cache_purge.git
clone modules/nginx-http-slice https://github.com/alibaba/nginx-http-slice.git

export BUILD_TYPE=Release
download-source modules/incubator-pagespeed-ngx https://github.com/apache/incubator-pagespeed-ngx/archive/latest-stable.tar.gz
download-source modules/incubator-pagespeed-ngx/psol https://dl.google.com/dl/page-speed/psol/1.12.34.2-x64.tar.gz

clone modules/echo-nginx-module https://github.com/openresty/echo-nginx-module.git
clone modules/headers-more-nginx-module https://github.com/openresty/headers-more-nginx-module.git
