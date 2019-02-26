#!/usr/bin/env bash

__LAST_DOWNLOAD_FILE=
function get_last_download() {
	echo "$__LAST_DOWNLOAD_FILE"
}

function download_file() {
	local URL="$1" TARGET
	TARGET=$(where_cache "$(basename "${URL}")")

	if [[ -e "${TARGET}" ]]; then
		echo "Download $TARGET - file exists."
		__LAST_DOWNLOAD_FILE="$TARGET"
		return
	fi

	mkdir -p "$(dirname "${TARGET}")"
	screen_run "Download $BASE" wget "${URL}" -c -O "${TARGET}.downloading"
	mv "${TARGET}.downloading" "${TARGET}"

	__LAST_DOWNLOAD_FILE="$TARGET"
}

function clone_repo() {
	local URL="$1" USER REPO TARGET
	REPO="$(basename "${URL}" .git)"
	USER="$(basename "$(dirname "${URL/://}")")"
	TARGET=$(where_cache "$USER/$REPO")

	if [[ -e "$TARGET" ]]; then
		push_dir "$TARGET"
		screen_run "Git Update" git fetch
		pop_dir
	else
		screen_run "Git Clone" git clone "$URL" "$TARGET"
	fi
	__LAST_DOWNLOAD_FILE="$TARGET"
}

function extract_downloaded(){
	local STRIP="$1"
	local BASENAME="$(basename "$__LAST_DOWNLOAD_FILE")"
	local TARGET="$__LAST_DOWNLOAD_FILE"

	case "$BASENAME" in
	*.tar.gz|*.tar.xz|*.tar.bz2)
		TARGET="${TARGET%.tar.gz}"
		TARGET="${TARGET%.tar.xz}"
		TARGET="${TARGET%.tar.bz2}"
		extract_tar "$__LAST_DOWNLOAD_FILE" "$TARGET" "$STRIP"
	;;
	default)
		die "Unknown zip format: $BASENAME"
	esac

	__LAST_DOWNLOAD_FILE="$TARGET"
}

function checkout_repo() {
	local BRANCH="${1-master}" REPO="$1" TARGET="$2"
	push_dir "$REPO"

	mkdir -p "$TARGET"
	screen_run bash -c "git archive '$BRANCH' | tar -vx -C '$TARGET'"

	pop_dir
}
