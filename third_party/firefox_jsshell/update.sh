#!/usr/bin/env bash
# Uploads a new version of the checked in JSShell CIPD packages
set -ex

if [ -z "$1" ]; then
  echo "Usage: update.sh version"
  exit 1
fi

tmpdir=$(mktemp -d)
cleanup() {
  rm -rf "$tmpdir"
}
trap cleanup EXIT HUP INT QUIT TERM PIPE
pushd "$tmpdir"

ARCH=("linux-amd64" "mac-amd64" "windows-amd64")
URL=https://archive.mozilla.org/pub/firefox/releases/$1/jsshell
curl $URL/jsshell-linux-x86_64.zip --output jsshell-linux-amd64.zip
curl $URL/jsshell-mac.zip --output jsshell-mac-amd64.zip
curl $URL/jsshell-win64.zip --output jsshell-windows-amd64.zip

for a in "${ARCH[@]}"
do
  filename="jsshell-$a.zip"
  unzip -qj $filename -d jsshell
  cipd create \
    -name dart/third_party/jsshell/$a \
    -in jsshell \
    -install-mode copy \
    -tag version:$1
  rm $filename
  rm -rf jsshell
done

popd

gclient setdep --var="jsshell_tag=version:$1"
