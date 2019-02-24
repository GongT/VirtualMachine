#!/usr/bin/env bash

function download_file() {
	local URL="$1"
	if [[ -z "$2" ]]; then
		local SAVE_AS="$(basename "${URL}")"
	else
		local SAVE_AS="$2"
	fi
	local TARGET=$(where_cache "${BASE}")

	if [[ -e "${TARGET}" ]]; then
		echo "Download $TARGET - file exists."
		return
	fi

	mkdir -p "$(dirname "${TARGET}")"
	screen_run "Download $BASE" wget "${URL}" -c -O "${TARGET}.downloading"
	mv "${TARGET}.downloading" "${TARGET}"
}

function clone_into() {
	local URL="$1"
	local SAVE_AS="$2"

	if [[ -e "$SAVE_AS" ]]; then
		push_dir "$SAVE_AS"
		screen_run "Git Update" git pull
		pop_dir
	else
		screen_run "Git Clone" git clone "$URL" .
	fi
}
