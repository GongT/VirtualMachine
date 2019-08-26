#!/usr/bin/env bash

function ensure_node_module() {
	local MPATH="/tmp/vm-install-script/node_modules/$1/package.json"
	if [[ ! -e "$MPATH" ]]; then
		echo "Fetch $1 from npm..."
		mkdir -p /tmp/vm-install-script
		pushd /tmp/vm-install-script &>/dev/null
		npm install --save "$1"
		popd &>/dev/null
	fi
}

function node_module_bin() {
	echo "/tmp/vm-install-script/node_modules/.bin/$1"
}

function create_machine_json() {
	local MACHINE_DEFINE="$1" TARGET

	TARGET=$(machine_path container.json)
	mkdir -p "$(dirname "${TARGET}")"

	echo "Parsing container json..."
	ensure_node_module json5
	local JSON5="$(node_module_bin json5)"
	"$JSON5" -o "${TARGET}" -s t "${MACHINE_DEFINE}"
	"$JSON5" -o "/tmp/validate.schema.json" -s t "$SCRIPT_INCLUDE_ROOT/container.schema.json5"
	echo "    save to: ${TARGET}."
	ensure_node_module ajv-cli
	local JSON5="$(node_module_bin ajv)"
	"$JSON5" -s "/tmp/validate.schema.json" -d "${TARGET}" >/dev/null
	echo "    schema check complete."
}

function query_json() {
	local TARGET="$(machine_path container.json)"
	cat "${TARGET}" | query_json_value "$*"
}
function query_condition() {
	local TARGET="$(machine_path container.json)"
	cat "${TARGET}" | query_json_condition "$*"
}

function query_json_value() {
	jq -M -r -c "try $1"
}
function query_json_condition() {
	jq -M -r -c -e "try $1" >/dev/null
}

function foreach_array() {
	# callback index index size < current
	local LINES=() QUERY="$1" CALLBACK="$2" VALUE I LEN
	shift
	shift
	LINES=($(query_json "$QUERY [] | @base64"))

	LEN="${#LINES[@]}"
	LEN=$(($LEN - 1))
	for I in "${!LINES[@]}" ; do
		VALUE="${LINES[$I]}"
		VALUE=$(echo "$VALUE" | base64 --decode)
		${CALLBACK} "$VALUE" "${I}" "${I}" "${LEN}" "$@"
	done
}

function foreach_object() {
	# callback value key index size < current
	local KEYS=() VALUE QUERY="$1" CALLBACK="$2" I LEN KEY KEY_QUOTE
	shift
	shift
	KEYS=($(query_json "try $QUERY | keys [] | @base64"))

	LEN="${#KEYS[@]}"
	LEN=$(($LEN - 1))
	for I in "${!KEYS[@]}" ; do
		KEY="$(echo "${KEYS[$I]}" | base64 --decode)"
		VALUE=$(query_json "$QUERY[\"$KEY\"]")
		${CALLBACK} "$VALUE" "${KEY}" "${I}" "${LEN}" "$@"
	done
}

function is_null_or_empty() {
	[[ -z "$1" ]] || [[ "$1" = "null" ]]
}
function is_null() {
	[[ "$1" = "null" ]]
}
