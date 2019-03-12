#!/usr/bin/env bash

cd "$( dirname "${BASH_SOURCE[0]}" )"
source ../include.sh

handle_exit

require_within

PREV_MACHINE="$CURRENT_MACHINE"

BUILD_SCRIPT="$(query_json ".compile.script")"
ARTIFACT_MAP=()
function convert_map() {
	local MAP_TO="$1" COMPILE_OUT="$2"
	ARTIFACT_MAP["$COMPILE_OUT"]="$(machine_path "$MAP_TO")"
}
foreach_object "$(query_json ".compile.artifacts")" convert_map
REQUIRE_PKGS="$(query_json ".compile.requirements.packages")"
REQUIRE_LIST="$(query_json ".compile.requirements.packagesFile")"

DOWNLOAD_LIST=()
function push_array() {
	DOWNLOAD_LIST+=("$1")
}
foreach_array '.compile.projects[].download' push_array

COMPILE_LIST=()
function prepare_script() {
	COMPILE_LIST+=("$1")
}
foreach_array '.compile.projects' prepare_script

within_machine build-env
if ! [[ -e "$(machine_path /bin/bash)" ]] ; then
	BUILD_ENV_FILE=$(realpath "$SCRIPT_INCLUDE_ROOT/../machines/build-env/build-env.container.json5")
	echo "${TEXT_ERROR}!!! Build Env not found, creating...${TEXT_RESET}"
	MACHINE_DEFINE_FILE="$BUILD_ENV_FILE" run_main "create-machine.sh"
fi
install_package "$REQUIRE_PKGS" "$REQUIRE_LIST"

clear_machine_install_logs

boot

if [[ ${#DOWNLOAD_LIST[@]} -ne 0 ]] ; then
	echo "Download and install compile environments:"
	for i in "${!DOWNLOAD_LIST[@]}" ; do
		run_download "${DOWNLOAD_LIST[$i]}"
	done
	echo "All download success"
else
	echo "Nothing to download."
fi

BUILD_SCRIPT_ROOT="$(machine_path "/opt/scripts/build")"
mkdir -p "$BUILD_SCRIPT_ROOT"

cp -rf -L "$SCRIPT_INCLUDE_ROOT/include.sh" "$SCRIPT_INCLUDE_ROOT/common" "$BUILD_SCRIPT_ROOT"
ENTRY_FILE_INNER="/opt/scripts/build/entry.sh"
ENTRY_FILE=$(machine_path "$ENTRY_FILE_INNER")
mkdir -p "$(dirname "$ENTRY_FILE")"
echo '#!/usr/bin/env bash
set -e

echo "-----------------------------"
env
echo "-----------------------------"

source "$(dirname "${BASH_SOURCE[0]}")/include.sh"
handle_exit

echo "running $1..."
main_exists || die "not exists..."
source_main "$1"
' > "$ENTRY_FILE"

function run_compile() {
	local TITLE=$1 SCRIPT=$2 TARGET_SCRIPT
	TARGET_SCRIPT=$(machine_path "/opt/scripts/build/main/build-$TITLE.sh")
	mkdir -p "$(dirname "$TARGET_SCRIPT")"
	cp -f -L "$SCRIPT" "$TARGET_SCRIPT"

	local RET_FILE="/var/$(date +%F.%H.%M.%S).${RANDOM}"
	machinectl shell \
		-E "http_proxy=$HTTP_PROXY" \
		-E "https_proxy=$HTTPS_PROXY" \
		-E "RET_FILE=$RET_FILE" \
		"$CURRENT_MACHINE" \
		/bin/bash --login "$ENTRY_FILE_INNER" "$(basename "$TARGET_SCRIPT")"
	local REMOTE_RET_FILE=$(machine_path "$RET_FILE")
	local RET=$(<"$REMOTE_RET_FILE")
	unlink "$REMOTE_RET_FILE"

	echo "return with code in file $REMOTE_RET_FILE."
	echo "    exit code is $RET"
	return ${RET}
}

echo "Compile projects:"
for JSON in "${COMPILE_LIST[@]}" ; do
	TITLE=$(echo "$JSON" | query_json_value ".title")
	ARTIFACT=$(echo "$JSON" | query_json_value ".artifact")
	SAVE_AT=$(echo "$JSON" | query_json_value ".saveAt")
	SCRIPT=$(echo "$JSON" | query_json_value ".script")

	if ! echo "$TITLE" | grep -qiE '^[a-z0-9_-]+$' ; then
		die "the value '$TITLE' is not a valid project name"
	fi

	if is_null_or_empty "$SAVE_AT" ; then
		SAVE_AT="$ARTIFACT"
	fi
	SAVE_AT=$(CURRENT_MACHINE="$PREV_MACHINE" machine_path "$SAVE_AT")
	ARTIFACT=$(machine_path "$ARTIFACT")
	SCRIPT=$(where_host "$SCRIPT")

	rm -rf "$ARTIFACT"
	mkdir -p "$ARTIFACT"

	screen_run "Compiling project $TITLE" run_compile "$TITLE" "$SCRIPT"

	mkdir -p "$(dirname "$SAVE_AT")"
	CP_LOG=$(cp -Tvrf -L "$ARTIFACT" "$SAVE_AT")
	echo "  - Copy $(echo "$CP_LOG" | wc -l) files to target machine."
done

end_within
