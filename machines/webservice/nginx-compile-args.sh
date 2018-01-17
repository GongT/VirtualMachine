#!/usr/bin/env bash
nginx -V 2>&1 \
	| grep 'configure arguments: ' \
	| sed 's/configure arguments: //'
