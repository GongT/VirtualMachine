#!/usr/bin/env bash

cd "$( dirname "${BASH_SOURCE[0]}" )"
source ../include.sh

function do_download_file() {
	local VAL TYPE URL SAVE_TO
	VAL=$(cat)
	TYPE=$(echo "$VAL" | query_json_value '.type')
	URL=$(echo "$VAL" | query_json_value '.url')

	SAVE_TO=$(echo "$VAL" | query_json_value '.saveTo')
	SAVE_TO=$(machine_path "$SAVE_TO")

	echo "Downloading file...${TEXT_MUTED}(from $URL)${TEXT_RESET}"

	case "$TYPE" in
	normal)
		download_file "$URL"
		if echo "$VAL" | query_json_condition ".extract" ; then
			extract_downloaded "$(echo "$VAL" | query_json_value '.stripPath // 0')"
		fi
		screen_run "Copy Result" cp -rvf "$(get_last_download)" "$SAVE_TO"
	;;
	github)
		URL="https://github.com/${URL}.git"
	;&
	git)
		clone_repo "$URL"
		screen_run "Checkout" checkout_repo \
			"$(echo "$VAL" | query_json_value '.branch // "master"')" \
			"$(get_last_download)" \
			"$SAVE_TO"
	;;
	*)
		die "Unknown download type: $VAL"
	esac

	echo "  - ${TEXT_OK}Success. ${TEXT_RESET}${TEXT_MUTED}(${COUNT} files)${TEXT_RESET}"
}

within_machine "$MACHINE_TO_INSTALL"

foreach_array '.download' do_download_file

end_within
