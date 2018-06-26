#!/usr/bin/env bash

set -e
set -o pipefail

cd /opt/nginx

echo "
set -e

cd nginx

./auto/configure \\" > compile.sh

for i in ./modules/*/ ; do
	echo -e "\t'--add-dynamic-module=.${i}' \\" >> compile.sh
done

echo -e "\t'--add-dynamic-module=../special-modules/njs/nginx' \\
\t'--modules-path=/opt/modules' \\
\t'--conf-path=/opt/config/nginx/nginx.conf' \\
\t'--with-debug' \\" >> compile.sh

function extract() {
	for i ; do
		echo -e "\t'${i}' \\"
	done
}

export -f extract

bash -c "extract $*" | \
  sed 's#/var/lib/nginx/tmp#/tmp#g' | \
  grep -v -- '--with-debug' | \
  grep -v -- '--conf-path' | \
  grep -v -- '--modules-path' | \
  grep -v -- '--add-dynamic-module' | \
  grep -v -- '--with-http_perl_module' | \
  sed 's/=dynamic//' \
    >> compile.sh

echo "

make BUILDTYPE=Debug -j $(nproc)

" >> compile.sh

function run-build() {
	bash compile.sh </dev/null

	mkdir -p ./dist
	cp  -r nginx/objs/nginx \
		nginx/objs/ngx_*.so \
		./dist/
	
	cd ./dist
	ls *.so | xargs -I FFF echo 'load_module "/opt/modules/FFF";' > load-all.conf
}
run-build 2>&1 | tee compile.log
