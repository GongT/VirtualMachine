#!/usr/bin/env bash

function extract_tar() {
	local FILE="$1"
	local TARGET="$2"
	local STRIP="${3-0}"

	mkdir -p "$TARGET"
	screen_run "Extract file" tar --strip-components="$STRIP" -xvf "$FILE" -C "$TARGET"
}
