#!/usr/bin/env bash

function die() {
	echo -e "\e[38;5;9m$@\e[0m" >&2
	exit 1
}

function clone() {
	local TO="$1"
	local URL="$2"
	
	if [ ! -e "$TO" ]; then
		git clone "$URL" "$TO" || die "failed to download content from $URL"
	fi
}

function download-file() {
	local TO="$1"
	local URL="$2"
	
	if [ ! -e "$TO" ]; then
		wget -c "$URL" -O "$TO.downloading" || die "failed to download tarball from $URL"
		mv "$TO.downloading" "$TO"
	fi
	echo "file saved: `pwd`/$TO"
}

function download-source() {
	local TO="$1"
	
	download-file "${TO}.tar.gz" "$2"
	
	if [ ! -e "$TO" ]; then
		mkdir "$TO"
		tar xf "$TO.tar.gz" --strip-components=1 -C "$TO" || {
			rm -r "$TO"
			die "failed to unzip file `pwd`/$TO.tar.gz"
		}
	fi
}

function dpush() {
	pushd $1 &>/dev/null
}
function dpop() {
	popd $1 &>/dev/null
}

function active-network() {
	systemctl start systemd-networkd systemd-resolved
}
