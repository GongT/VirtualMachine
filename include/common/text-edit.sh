#!/usr/bin/env bash

function prepend_if_not() {
	local WHAT="$1" TARGET="$2" DATA

	if [[ -e "$TARGET" ]] && grep -q "$WHAT" "$TARGET" ; then
		return 0
	fi

	mkdir -p "$(dirname "$TARGET")"
	touch "$TARGET"

	CONTENTS="$(grep -Ev '^$' "$TARGET" 2>/dev/null)"
	echo "$WHAT\n${CONTENTS}\n" > "$TARGET"

	return 1
}

function append_if_not() {
	local WHAT="$1" TARGET="$2" MARK="${3-$1}" CONTENTS

	if [[ -e "$TARGET" ]] && grep -q "$MARK" "$TARGET" ; then
		return 0
	fi

	mkdir -p "$(dirname "$TARGET")"
	touch "$TARGET"

	CONTENTS="$(grep -Ev '^$' "$TARGET" 2>/dev/null)"
	echo "${CONTENTS}\n$WHAT\n" > "$TARGET"

	return 1
}
