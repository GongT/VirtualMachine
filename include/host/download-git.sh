#!/usr/bin/env bash

function clone_repo() {
	local URL="$1" TARGET="$2"

	echo "\n"
	if [[ -e "$TARGET" ]]; then
		echo "target exists. run fetch. (in dir $TARGET)"
		push_dir "$TARGET"
		git fetch
		pop_dir
		echo "    git fetch complete."
	else
		echo "target Not exists. run clone --bare $URL $TARGET."
		git clone --verbose --progress --bare "$URL" "$TARGET"
		echo "    git clone complete."
	fi
}

function checkout_repo() {
	local BRANCH="$1" REPO="$2" TARGET="$3"

	echo "checkout $BRANCH branch of bare repo $REPO to $TARGET"
	mkdir -p "$TARGET/.git"
	cp -ruT -L "$REPO" "$TARGET/.git"

	push_dir "$TARGET"
	git init .
	sed -i.bak '/bare = true/d' ".git/config"
	if [[ -z "$BRANCH" ]]; then
		git checkout --progress --force
	else
		git checkout --progress --force -B "$BRANCH"
	fi
	pop_dir
}

