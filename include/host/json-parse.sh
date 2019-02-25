#!/usr/bin/env bash

function create_machine_json() {
	local MACHINE_DEFINE="$1" TARGET

	TARGET=$(machine_path container.json)
	mkdir -p "$(dirname "${TARGET}")"

	echo "Parsing container json: ${MACHINE_DEFINE}." >&2
	node --experimental-modules \
		"${SCRIPT_INCLUDE_ROOT}/parse-validate-json.mjs" \
		"${MACHINE_DEFINE}" \
		"${TARGET}"
	echo "    save to: ${TARGET}." >&2
}

function query_json() {
	local TARGET="$(machine_path container.json)"
	cat "${TARGET}" | query_json_value "$*"
}

function query_json_value() {
	jq -M -r -c "try $1"
}
function query_json_condition() {
	jq -M -r -c -e "try $1"
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
		echo "$VALUE" | base64 --decode | ${CALLBACK} "${I}" "${I}" "${LEN}" "$@"
	done
}

function foreach_object() {
	# callback key index size < current
	local KEYS=() QUERY="$1" CALLBACK="$2" I LEN KEY KEY_QUOTE
	shift
	shift
	KEYS=($(query_json "try $QUERY | keys [] | @base64"))

	LEN="${#KEYS[@]}"
	LEN=$(($LEN - 1))
	for I in "${!KEYS[@]}" ; do
		KEY="$(echo "${KEYS[$I]}" | base64 --decode)"
		query_json "$QUERY[\"$KEY\"]" | ${CALLBACK} "${KEY}" "${I}" "${LEN}" "$@"
	done
}

function is_null_or_empty() {
	[[ -z "$1" ]] || [[ "$1" = "null" ]]
}
function is_null() {
	[[ "$1" = "null" ]]
}
