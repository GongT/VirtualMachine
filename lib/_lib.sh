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
	else
		pushd "$TO" &>/dev/null
		git pull
		popd &>/dev/null
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

function download-github() {
	local TARGET="$1"
	local REPO="$2"
	local API="https://api.github.com/repos/$REPO/tags"
	if [ ! -e "$TARGET" ]; then
		mkdir -p "$TARGET"
		echo "Requesting target api: $API..."
		local DOWNLOAD_URL=$(
			curl -L "$API" | \
				jq -r '[.[] | select(.name | test(".rc.") | not)] [0] .tarball_url'
		)

		echo "DOWNLOAD_URL=$DOWNLOAD_URL"
		if [ -z "$DOWNLOAD_URL" ]; then
			die "Cannot download source from $REPO"
		fi

		echo "downloading to $TARGET"
		curl -L "$DOWNLOAD_URL" | \
			tar xz --strip-components=1 -C "$TARGET"
	else
		echo "target folder $TARGET is exists"
	fi
}

function download-master() {
	local TARGET="$1"
	local REPO="$2"

	if [ ! -e "$TARGET" ]; then
		mkdir -p "$TARGET"
		echo "downloading $REPO to $TARGET"
		curl -L "https://github.com/$REPO/archive/master.tar.gz" | \
			tar xz --strip-components=1 -C "$TARGET"
	else
		echo "target folder $TARGET is exists"
	fi
}
