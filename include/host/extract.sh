#!/usr/bin/env bash

function extract_tar() {
	local FILE="$1"
	local TARGET="$2"
	local STRIP="${3-0}"

	mkdir -p "$TARGET"
	tar --strip-components="${STRIP-0}" -xvf "$FILE" -C "$TARGET"
}

function extract_downloaded(){
	local DOWNLOADED_FILE="$1" STRIP="$3" TARGET="$2"
	local BASENAME="$(basename "$DOWNLOADED_FILE")" EXTRACT_LOG=""

	echo "Extract file: $DOWNLOADED_FILE"
	echo "        to: $TARGET"
	echo "        strip: $STRIP"
	case "$BASENAME" in
	*.zip)
		if ! [[ -e "$DOWNLOADED_FILE.tar.gz" ]]; then
			local TEMP_DIR="$DOWNLOADED_FILE.temp"
			mkdir -p "$TEMP_DIR"
			push_dir "$TEMP_DIR"
			unzip -d . "$DOWNLOADED_FILE" >/dev/null
			tar czf "$DOWNLOADED_FILE.tar.gz" .
			pop_dir
		fi
		DOWNLOADED_FILE="$DOWNLOADED_FILE.tar.gz"
	;&
	*.tar.gz|*.tar.xz|*.tar.bz2)
		EXTRACT_LOG=$(extract_tar "$DOWNLOADED_FILE" "$TARGET" "$STRIP")
	;;
	*)
		die "Unknown zip format: $DOWNLOADED_FILE"
	esac
	echo "  Extract complete, $(echo "$EXTRACT_LOG" | wc -l) files."
}
