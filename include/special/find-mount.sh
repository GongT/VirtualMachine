#!/usr/bin/env bash

NSPAWN_FILE="/var/lib/machines/$MACHINE.nspawn"
START='# AUTO_CREATE_SYMLINK_RESOLVE_START'
END='# AUTO_CREATE_SYMLINK_RESOLVE_END'

function resolve_symlink() {
	local P="$1" DIR TARGET NEXT

	echo "Bind=$P" >> "$NSPAWN_FILE"

	if [[ -L "$P" ]]; then
		DIR=$(dirname "$P")
		TARGET=$(readlink "$P")

		if [[ "${TARGET:0:1}" = "/" ]]; then
			NEXT="$TARGET"
		else
			NEXT=$(realpath -m -L "$DIR/$TARGET")
		fi

		resolve_symlink "$NEXT"
	fi
}

sed -i "/$START/,/$END/d" "$NSPAWN_FILE"
sed -i "/^$/d" "$NSPAWN_FILE"

echo "" >> "$NSPAWN_FILE"
echo "$START" >> "$NSPAWN_FILE"
resolve_symlink "$1"
echo "$END" >> "$NSPAWN_FILE"
