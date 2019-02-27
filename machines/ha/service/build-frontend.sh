#!/usr/bin/env bash

set -e

echo "installing node_modules..."
yarn --verbose
yarn add natives@^1.1.3
rm -rf node_modules/gulp/node_modules/natives

echo "building..."
script/build_frontend
