function simple_download_file() {
	local URL="$1" TARGET="$2"

	if [[ -e "${TARGET}" ]]; then
		echo "Download file exists: $TARGET."
		return
	fi

	wget_progress "$URL" "$TARGET"
}

function wget_progress(){
	local URL="$1" TARGET="$2"

	echo "run wget: $URL -> ${TARGET}.downloading"

	mkdir -p "$(dirname "${TARGET}")"
	wget "$URL" -c -O "${TARGET}.downloading" --quiet --show-progress --progress=bar:force:noscroll

	echo "    move temp .downloading to $TARGET"
	mv "${TARGET}.downloading" "${TARGET}"
}
