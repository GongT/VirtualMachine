#!/usr/bin/env bash

/usr/lib/systemd/systemd-networkd-wait-online host0

cd /opt/source/nginx

########## download psol for ngx_speed
export BUILD_TYPE=Release
PSOL_SOURCE="$(sed 's/$BIT_SIZE_NAME/x64/g' modules/incubator-pagespeed-ngx/PSOL_BINARY_URL)"
ZIP_FILE="/mnt/cache/Download/pagespeed-psol/$(basename "$PSOL_SOURCE")"
simple_download_file "$PSOL_SOURCE" "$ZIP_FILE"
echo "extract $ZIP_FILE to `pwd`/modules/incubator-pagespeed-ngx"
tar xf "$ZIP_FILE" -C modules/incubator-pagespeed-ngx
echo "    extract ok"

########### patch for rtmp
#echo "apply patch on file modules/nginx-rtmp-module/ngx_rtmp_eval.c"
#push_dir modules/nginx-rtmp-module
#echo '
#diff -Nur a/ngx_rtmp_eval.c b/ngx_rtmp_eval.c
#--- a/ngx_rtmp_eval.c	2018-06-02 19:23:28.993466673 +0200
#+++ b/ngx_rtmp_eval.c	2018-06-02 19:23:26.532371311 +0200
#@@ -166,6 +166,7 @@
#                         state = ESCAPE;
#                         continue;
#                 }
#+				 /* fall through */
#
#             case ESCAPE:
#                 ngx_rtmp_eval_append(&b, &c, 1, log);
#' | patch -b ngx_rtmp_eval.c
#pop_dir

########### Nginx binary
echo "
set -e

cd /opt/source/nginx/core

export LUAJIT_LIB=/usr/lib64
export LUAJIT_INC=/usr/include/luajit-2.1

./auto/configure \\" > configure.sh

for i in ./modules/*/ ; do
	echo -e "\t'--add-module=.${i}' \\" >> configure.sh
done

echo -e "\t'--add-module=../special-modules/njs/nginx' \\
\t'--modules-path=/opt/modules' \\
\t'--prefix=/usr/' \\
\t'--sbin-path=/usr/sbin/nginx' \\
\t'--modules-path=/usr/nginx/modules' \\
\t'--conf-path=/etc/nginx/nginx.conf' \\
\t'--error-log-path=/var/log/nginx/error.log' \\
\t'--http-log-path=/var/log/nginx/access.log' \\
\t'--http-client-body-temp-path=/tmp/client_body' \\
\t'--http-proxy-temp-path=/tmp/proxy' \\
\t'--http-fastcgi-temp-path=/tmp/fastcgi' \\
\t'--http-uwsgi-temp-path=/tmp/uwsgi' \\
\t'--http-scgi-temp-path=/tmp/scgi' \\
\t'--pid-path=/run/nginx.pid' \\
\t'--lock-path=/run/lock/subsys/nginx' \\
\t'--user=nginx' \\
\t'--group=nginx' \\" >> configure.sh

function with() {
	echo -e "\t'--with-$*' \\" >> configure.sh
}
function without() {
	echo -e "\t'--without-$*' \\" >> configure.sh
}

with compat                                           # dynamic modules compatibility
without select_module
without poll_module
with threads # enable thread pool support
with file-aio                                         # enable file AIO support
with http_ssl_module                                  # enable ngx_http_ssl_module
with http_v2_module                                   # enable ngx_http_v2_module
with http_realip_module                               # enable ngx_http_realip_module
with http_addition_module                             # enable ngx_http_addition_module
with http_xslt_module                                 # enable ngx_http_xslt_module
with http_xslt_module                                 # enable dynamic ngx_http_xslt_module
with http_image_filter_module                         # enable ngx_http_image_filter_module
with http_geoip_module                                # enable dynamic ngx_http_geoip_module
with http_sub_module                                  # enable ngx_http_sub_module
with http_dav_module                                  # enable ngx_http_dav_module
with http_flv_module                                  # enable ngx_http_flv_module
with http_mp4_module                                  # enable ngx_http_mp4_module
with http_gunzip_module                               # enable ngx_http_gunzip_module
with http_gzip_static_module                          # enable ngx_http_gzip_static_module
with http_auth_request_module                         # enable ngx_http_auth_request_module
with http_random_index_module                         # enable ngx_http_random_index_module
with http_secure_link_module                          # enable ngx_http_secure_link_module
with http_degradation_module                          # enable ngx_http_degradation_module
with http_slice_module                                # enable ngx_http_slice_module
with http_stub_status_module                          # enable ngx_http_stub_status_module
# with http_perl_module                                 # enable dynamic ngx_http_perl_module
with stream                                           # enable TCP/UDP proxy module
with stream_ssl_module                                # enable ngx_stream_ssl_module
with stream_realip_module                             # enable ngx_stream_realip_module
with stream_geoip_module                              # enable dynamic ngx_stream_geoip_module
with stream_ssl_preread_module                        # enable ngx_stream_ssl_preread_module
with google_perftools_module                          # enable ngx_google_perftools_module
# with cpp_test_module                                  # enable ngx_cpp_test_module
with pcre                                             # force PCRE library usage
with pcre-jit                                         # build PCRE with JIT compilation support
with libatomic                                        # force libatomic_ops library usage
with debug                                            # enable debug logging

LD_OPT=(
	-Wl,-z,defs
	-Wl,-z,now
	-Wl,-z,relro
	-Wl,-E
)
CC_OPT=(
	-O2
	-g
	-pipe
	-Wall
	-Werror=format-security
	-Wp,-D_FORTIFY_SOURCE=2
	-Wp,-D_GLIBCXX_ASSERTIONS
	-fexceptions
	-fstack-protector-strong
	-grecord-gcc-switches
	-m64
	-mtune=generic
	-fasynchronous-unwind-tables
	-fstack-clash-protection
	-Wno-error
)

with cc-opt=${CC_OPT[*]}
with ld-opt=${LD_OPT[*]}

echo "#!/bin/bash
set -e

cd /opt/source/nginx/core
make BUILDTYPE=Debug -j
make install DESTDIR=/opt/nginx

" > make.sh

bash configure.sh </dev/null # yes | will return fail
echo "\n\n--------------------------------------------\nCompile OK. Start make.\n\n"
bash make.sh