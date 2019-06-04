#!/usr/bin/env bash
# Uploads a new version of d8 CIPD package
set -e
set -x

if [ -z "$1" ]; then
  echo "Usage: update.sh version"
  exit 1
fi

version=$1

tmpdir=$(mktemp -d)
cleanup() {
  rm -rf "$tmpdir"
}
trap cleanup EXIT HUP INT QUIT TERM PIPE
cd "$tmpdir"

for file in "babel.js" "babel.min.js" "LICENSE"
do
  curl -o $file "https://unpkg.com/@babel/standalone@$version/$file"
done

cipd create \
  -name dart/third_party/babel \
  -in . \
  -install-mode copy \
  -tag version:$version
