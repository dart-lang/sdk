#!/usr/bin/env bash
# Uploads a new version of the checked in SDK CIPD packages
set -e
set -x

if [ -z "$1" ]; then
  echo "Usage: update.sh version"
  exit 1
fi

case "$1" in
*-*.0.dev) channel="dev";;
*-*.*.beta) channel="beta";;
*) channel="stable";;
esac

tmpdir=$(mktemp -d)
cleanup() {
  rm -rf "$tmpdir"
}
trap cleanup EXIT HUP INT QUIT TERM PIPE
pushd "$tmpdir"

gsutil.py cp "gs://dart-archive/channels/$channel/release/$1/sdk/dartsdk-linux-x64-release.zip" .
unzip -q dartsdk-linux-x64-release.zip -d sdk
cipd create \
  -name dart/dart-sdk/linux-amd64 \
  -in sdk \
  -install-mode copy \
  -tag version:$1 \
  -ref $channel
rm -rf sdk

gsutil.py cp "gs://dart-archive/channels/$channel/release/$1/sdk/dartsdk-linux-arm-release.zip" .
unzip -q dartsdk-linux-arm-release.zip -d sdk
cipd create \
  -name dart/dart-sdk/linux-armv6l \
  -in sdk \
  -install-mode copy \
  -tag version:$1 \
  -ref $channel
rm -rf sdk

gsutil.py cp "gs://dart-archive/channels/$channel/release/$1/sdk/dartsdk-linux-arm64-release.zip" .
unzip -q dartsdk-linux-arm64-release.zip -d sdk
cipd create \
  -name dart/dart-sdk/linux-arm64 \
  -in sdk \
  -install-mode copy \
  -tag version:$1 \
  -ref $channel
rm -rf sdk

gsutil.py cp "gs://dart-archive/channels/$channel/release/$1/sdk/dartsdk-macos-x64-release.zip" .
unzip -q dartsdk-macos-x64-release.zip -d sdk
cipd create \
  -name dart/dart-sdk/mac-amd64 \
  -in sdk \
  -install-mode copy \
  -tag version:$1 \
  -ref $channel
rm -rf sdk

gsutil.py cp "gs://dart-archive/channels/$channel/release/$1/sdk/dartsdk-windows-x64-release.zip" .
unzip -q dartsdk-windows-x64-release.zip -d sdk
cipd create \
  -name dart/dart-sdk/windows-amd64 \
  -in sdk \
  -install-mode copy \
  -tag version:$1 \
  -ref $channel
rm -rf sdk

popd

gclient setdep --var="sdk_tag=version:$1"
