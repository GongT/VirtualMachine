#!/usr/bin/env bash

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
\t'--conf-path=/opt/config/nginx/nginx.conf' \\" >> compile.sh

function extract() {
	for i ; do
		echo -e "\t'${i}' \\"
	done
}

export -f extract

bash -c "extract $*" | \
  sed 's#/var/lib/nginx/tmp#/tmp#g' | \
  grep -v -- '--conf-path' | \
  grep -v -- '--modules-path' | \
  grep -v -- '--add-dynamic-module' | \
  grep -v -- '--with-http_perl_module' | \
  sed 's/=dynamic//' \
    >> compile.sh

echo "

make -j $(nproc)

" >> compile.sh

trap "
RET=\$?
tput rmcup
if [ -e error.log ]; then
	cat error.log
	unlink error.log
fi
exit \$RET
" EXIT
tput smcup

function run-build() {
	bash compile.sh </dev/null

	mkdir -p ./dist
	cp  -r nginx/objs/nginx \
		nginx/objs/ngx_*.so \
		./dist/
	
	cd ./dist
	ls *.so | xargs -I FFF echo 'load_module "/opt/modules/FFF";' > load-all.conf
}
run-build 2>&1 | tee error.log
unlink error.log
