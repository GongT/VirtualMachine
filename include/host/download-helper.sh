#!/usr/bin/env bash

function copy_downloaded() {
	local DOWNLOADED_FILE="$1" SAVE_TO="$2"
	local CP_LOG

	echo "Copy download result..."
	CP_LOG="$(cp -rvf -L "$DOWNLOADED_FILE" "$SAVE_TO")"
	echo "    Copy finished, $(echo "$CP_LOG" | wc -l) files."
}
