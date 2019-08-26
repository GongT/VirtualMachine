#!/usr/bin/env bash

function __parse_download_file_info() {
	local VAL="$1"
	TYPE=$(echo "$VAL" | query_json_value '.type')
	URL=$(echo "$VAL" | query_json_value '.url')

	if echo "$VAL" | query_json_condition ".extract" ; then
		EXTRACT=yes
	else
		EXTRACT=no
	fi

	SAVE_TO=$(echo "$VAL" | query_json_value '.saveTo')
	STRIP_PATH="$(echo "$VAL" | query_json_value '.stripPath // 1')"

	SAVE_TO=$(machine_path "$SAVE_TO")

	BRANCH=$(echo "$VAL" | query_json_value '.branch // "master"')

	CACHE_FILE=$(echo "$VAL" | query_json_value '.tempFile // ""')
}

function download_inner() {
	local TYPE URL SAVE_TO STRIP_PATH EXTRACT CACHE_FILE BRANCH
	__parse_download_file_info "$1"

	echo "Downloading file:"
	echo "type=$TYPE"
	echo "url=$URL"
	echo "save_to=$SAVE_TO"
	echo "strip_path=$STRIP_PATH"
	echo "extract=$EXTRACT"
	echo "branch=$BRANCH"
	echo "CACHE_FILE=$CACHE_FILE"
	echo ""
	echo ""

	case "$TYPE" in
	normal)
		CACHE_FILE=${CACHE_FILE:-"$(basename "${URL}")"}
		CACHE_FILE=$(where_cache "Download/$CACHE_FILE")
		simple_download_file "$URL" "$CACHE_FILE"
		if [[ "$EXTRACT" = "yes" ]] ; then
			extract_downloaded "$CACHE_FILE" "$SAVE_TO" "$STRIP_PATH"
		else
			copy_downloaded "$CACHE_FILE" "$SAVE_TO"
		fi
	;;
	github-release)
		CACHE_FILE=${CACHE_FILE:-"${URL////-}.tar.gz"}
		CACHE_FILE=$(where_cache "Download/$CACHE_FILE")
		download_github_release "$URL" "$CACHE_FILE"
		extract_downloaded "$CACHE_FILE" "$SAVE_TO" "$STRIP_PATH"
	;;
	github)
		URL="https://github.com/${URL}.git"
	;&
	git)
		CACHE_FILE=${CACHE_FILE:-"$(get_repo_name_from_url "$URL")"}
		CACHE_FILE=$(where_cache "Download/$CACHE_FILE")
		clone_repo "$URL" "$CACHE_FILE"
		checkout_repo "$BRANCH" "$CACHE_FILE" "$SAVE_TO"
	;;
	*)
		die "Unknown download type: $VAL"
	esac
	echo "Complete Download: $SAVE_TO."
}

function run_download() {
	screen_run "Download file $2" download_inner "$1"
}
