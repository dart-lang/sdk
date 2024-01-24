#!/usr/bin/env bash
# Uploads a new version of the checked in jsc CIPD packages
# jsc is the JavaScriptCore shell from WebKit.
#
# Only the latest builds for the last few days are available
# for download. They are indexed by build number.
# This script only downloads the latest build, and uploads
# it to CIPD with the build number as the version tag.
# It updates DEPS to download that version of jsc from CIPD.
set -ex

tmpdir=$(mktemp -d)
cleanup() {
  rm -rf "$tmpdir"
}
trap cleanup EXIT HUP INT QUIT TERM PIPE
pushd "$tmpdir"

URL=https://webkitgtk.org/jsc-built-products/x86_64/release
LATEST=$(curl $URL/LAST-IS)
VERSION=${LATEST%@main.zip}
curl $URL/$LATEST --output main.zip
filename="main.zip"
unzip -q $filename -d jsc
cipd create \
  -name dart/third_party/jsc/linux-amd64 \
  -in jsc \
  -install-mode copy \
  -tag version:$VERSION
rm $filename
rm -rf jsc
popd

gclient setdep --var="jsc_tag=version:$VERSION"
