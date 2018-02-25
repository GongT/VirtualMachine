#!/bin/sh

if [ -n "${GOPATH}" ]; then
	GOPATH+=":"
fi
if [ -n "${GO_BIN_PATH}" ]; then
	GO_BIN_PATH+=":"
fi

if [ -z "${HOME}" ]; then
	export GOPATH+="/data/golang"
	GO_BIN_PATH+="/data/golang/bin"
else
	export GOPATH+="/data/golang:${HOME}/golang"
	GO_BIN_PATH+="/data/golang/bin:${HOME}/golang/bin"
fi

export PATH="${PATH}:/usr/local/go/bin:${GO_BIN_PATH}"
