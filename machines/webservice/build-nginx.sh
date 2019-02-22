#!/usr/bin/env bash

set -e
set -o pipefail

cd /opt/nginx-source

echo "
set -e

cd nginx

export LUAJIT_LIB=/usr/lib64
export LUAJIT_INC=/usr/include/luajit-2.1

./auto/configure \\" > configure.sh

for i in ./modules/*/ ; do
	echo -e "\t'--add-module=.${i}' \\" >> configure.sh
done

echo -e "\t'--add-module=../special-modules/njs/nginx' \\
\t'--modules-path=/opt/modules' \\
\t'--prefix=/opt/nginx' \\
\t'--sbin-path=/opt/nginx/nginx' \\
\t'--modules-path=/opt/nginx/modules' \\
\t'--conf-path=/opt/nginx/etc/nginx.conf' \\
\t'--error-log-path=/var/log/nginx/error.log' \\
\t'--http-log-path=/var/log/nginx/access.log' \\
\t'--http-client-body-temp-path=/tmp/client_body' \\
\t'--http-proxy-temp-path=/tmp/proxy' \\
\t'--http-fastcgi-temp-path=/tmp/fastcgi' \\
\t'--http-uwsgi-temp-path=/tmp/uwsgi' \\
\t'--http-scgi-temp-path=/tmp/scgi' \\
\t'--pid-path=/run/nginx.pid' \\
\t'--lock-path=/run/lock/subsys/nginx' \\
\t'--user=nginx --group=nginx' \\
\t'--conf-path=/opt/config/nginx/nginx.conf' \\" >> configure.sh

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
	-mcet
	-Wno-error
)

with cc-opt=${CC_OPT[*]}
with ld-opt=${LD_OPT[*]}

echo "#!/bin/bash
set -e

cd nginx
make BUILDTYPE=Debug -j
make install

" > make.sh

function run-build() {
	set -e
	bash configure.sh </dev/null
	bash make.sh
	systemctl cat nginx > /opt/nginx/nginx.service
}
run-build 2>&1 | tee compile.log
