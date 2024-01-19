#!/usr/bin/env bash
# Uploads a new version of d8 CIPD package
set -e
set -x

if [ -z "$1" ]; then
  echo "Usage: update.sh version"
  exit 1
fi

version=$1
major=$(echo "$version" | cut -d'.' -f1)
minor=$(echo "$version" | cut -d'.' -f2)
patch=$(echo "$version" | cut -d'.' -f3)

tmpdir=$(mktemp -d)
cleanup() {
  rm -rf "$tmpdir"
}
trap cleanup EXIT HUP INT QUIT TERM PIPE
cd "$tmpdir"

arch=("linux64" "linux-arm64" "mac64" "mac-arm64" "win64")
path=("linux/x64" "linux/arm64" "macos/x64" "macos/arm64" "windows/x64")

for i in "${!arch[@]}"
do
  filename="v8-${arch[$i]}-rel-$version.zip"
  gsutil.py cp "gs://chromium-v8/official/canary/$filename" .
  mkdir -p d8/${path[$i]}
  unzip -q $filename -d d8/${path[$i]}
  rm $filename
done

cipd create \
  -name dart/d8 \
  -in d8 \
  -install-mode copy \
  -tag version:$version \
  -tag version:$major.$minor.$patch \
  -tag version:$major.$minor
