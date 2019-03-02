#!/usr/bin/env bash

function get_repo_name_from_url() {
	local USER REPO
	USER=$(basename "$(dirname "${URL/://}")")
	REPO=$(basename "${URL}" .git)

	echo "$USER/$REPO"
}

function download_github_release() {
	local REPO="$1" TARGET="$2" DOWNLOAD_URL API

	echo "Github release download to $TARGET."

	if [[ -e "${TARGET}" ]]; then
		echo "  - exists."
		return
	fi

	API="https://api.github.com/repos/$REPO/tags"
	echo "  Request target api: $API..."
	DOWNLOAD_URL=$(
		curl -L "$API" | \
			query_json_value '[.[] | select(.name | test(".rc.") | not)] [0] .tarball_url'
	)

	echo "  Download url is: $DOWNLOAD_URL"
	if [[ -z "$DOWNLOAD_URL" ]]; then
		die "Cannot download source from $REPO"
	fi

	wget_progress "$DOWNLOAD_URL" "$TARGET"
}
